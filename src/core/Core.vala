using GObject, Plugins;

namespace LAview.Core {

	/**
	 * LAview Core.
	 */
	public class Core : Object, IHost, IHostCore {

		/*                          **
		 * --- I N T E R F A C E --- *
		 */                       /**/

		AppSettings settings;

		public string lyx_path {
			get { return settings.lyx_path; }
			set { settings.lyx_path = value; }
		}

		public string latexmk_pl_path {
			get { return settings.latexmk_pl_path; }
			set { settings.latexmk_pl_path = value; }
		}

		public string perl_path {
			get { return settings.perl_path; }
			set { settings.perl_path = value; }
		}

		public string data_path {
			get { return settings.data_path; }
			set { settings.data_path = value; }
		}

		public string object_path {
			get { return settings.object_path; }
			set { settings.object_path = value; }
		}

		public Gee.HashMap<Type, PluginData> data_plugins = new Gee.HashMap<Type, PluginData>();
		public Gee.HashMap<Type, PluginObject> object_plugins = new Gee.HashMap<Type, PluginObject>();

		/**
		 * Load Data Modules.
		 */
		public void load_data_modules (string dir_path) {
			Gee.ArrayList<Plugins.Module> tmp_modules = null;
			GObject.Plugins.load_modules (dir_path, ref tmp_modules);
			foreach (var m in tmp_modules) {
				if (!data_modules.contains(m)) {
					data_modules.add(m);
					var plugin_data = m.create_instance (this) as PluginData;
					data_plugins[m.get_plugin_type()] = plugin_data;
					data_plugins2[plugin_data.get_name()] = plugin_data;
				}
			}
		}

		/**
		 * Load Protocol Objects Modules.
		 */
		public void load_object_modules (string dir_path) {
			Gee.ArrayList<Plugins.Module> tmp_modules = null;
			GObject.Plugins.load_modules (dir_path, ref tmp_modules);
			foreach (var m in tmp_modules) {
				if (!object_modules.contains(m)) {
					object_modules.add(m);
					var plugin_object = m.create_instance (this) as PluginObject;
					object_plugins[m.get_plugin_type()] = plugin_object;
					object_plugins2[plugin_object.get_name()] = plugin_object;
				}
			}
		}

		/**
		 * Unload all Modules.
		 */
		public void unload_modules () {
			GObject.Plugins.unload_modules (data_modules);
			GObject.Plugins.unload_modules (object_modules);
		}

		public Core () throws Error {

			/* Initialization */
			AppDirs.init ();
			settings = new AppSettings();

			load_data_modules (AppDirs.data_plugins_dir);
			load_object_modules (AppDirs.object_plugins_dir);

			if (File.new_for_path (data_path).query_exists())
				load_data_modules (data_path);

			if (File.new_for_path (object_path).query_exists())
				load_object_modules (object_path);

			load_templates_list ();
			clear_cache ();
		}

		public string get_cache_dir () {
			return AppDirs.cache_dir;
		}

		public string[] get_templates_readable_names () {
			string[] names = {};
			foreach (var t in templates)
				names += t.get_readable_name ();
			return names;
		}

		public string get_template_path_by_index (int index) {
			return templates[index].get_path ();
		}

		public void add_template (string path) {
			var file = File.new_for_path (path);
			if (!file.query_exists() || file.query_file_type(FileQueryInfoFlags.NONE) != FileType.REGULAR)
				return;
			if (path.has_suffix ("lyx")) {
				var t = new LyxTemplate(path);
				if (!templates.contains (t))
					templates.add (t);
			} else if (path.has_suffix ("tex")) {
				var t = new TexTemplate(path);
				if (!templates.contains (t))
					templates.add (t);
			}
			save_templates_list ();
		}

		public void remove_template (int index) {
			if (index < templates.size)
				templates.remove_at (index);
			save_templates_list ();
		}

		public string[] get_objects_list (int template_index) throws Error {
			if (template_index == last_template_index) return objects_list;
			last_template_index = template_index;

			/* clear */
			clear_cache ();
			requests = new Gee.HashMap<string, Gee.HashMap<string, AnswerValue>> ();
			objects_list = { };
			composed_objects = { };

			var converter = new Conv.Converter.new_with_paths (lyx_path, latexmk_pl_path, perl_path);
			var t_path = Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.cache_dir, "template.tex");
			var lyx_file_path = templates[template_index].get_path();
			try {
				var sp = converter.lyx2tex (lyx_file_path, t_path);
				#if (UNIX)
					if (sp.wait_check() == false) throw new IOError.FAILED("");
				#elif (WINDOWS)
					sp.wait();
					if (!File.new_for_path(t_path).query_exists()) throw new IOError.FAILED("");
				#else
					assert_not_reached ();
				#endif
			} catch (Error e) {
				throw new IOError.FAILED(_("Error running lyx2tex subprocess for ")+lyx_file_path+".");
			}

			/* parse TeX */
			string contents;
			FileUtils.get_contents (t_path, out contents);
			document = LAview.parse (contents);

			var doc_stack = new Queue<IDoc> ();
			doc_stack.push_tail (document);
			recursive_walk (doc_stack, requests, Stage.ANALYSE);

			// Return readable objects names by requests and objects plugins readable names
			foreach (var req in requests.entries) {
				string object_suffix, object_cmd;
				var plugin = find_plugin (req.key, out object_suffix, out object_cmd);
				if (plugin != null) {
					objects_list += plugin.get_readable_name() + " " + object_suffix;
					composed_objects += false;
				}
			}

			return objects_list;
		}

		public bool compose_object (Object parent, int object_index) throws Error {
			var cnt = object_index;
			foreach (var req in requests.entries)
				if (cnt-- == 0) {
					string object_suffix, object_cmd;
					var plugin = find_plugin (req.key, out object_suffix, out object_cmd);
					var result = object_plugins2[plugin.get_name()].compose(parent, req.value);
					if (composed_objects[object_index] == false && result == true) {
						composed_objects[object_index] = true;
						objects_list[object_index] = "✔ " + objects_list[object_index];
					}
				}
			return composed_objects[object_index];;
		}

		public Subprocess print_document () throws Error {
			foreach (var c in composed_objects)
				if (c == false)
					throw new IOError.FAILED (_("Prepare document first."));
			generate_document_tex ();
			var converter = new Conv.Converter.new_with_paths (lyx_path, latexmk_pl_path, perl_path);
			return converter.tex2pdf (doc_tex_path(), doc_pdf_path());
		}

		public string get_lyx_file_path () throws Error {
			foreach (var c in composed_objects)
				if (c == false)
					throw new IOError.FAILED (_("Prepare document first."));
			return generate_document_lyx();
		}

		public string get_pdf_file_path () throws Error {
			var pdf_path = Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.cache_dir, "document.pdf");
			if (!File.new_for_path(pdf_path).query_exists())
				throw new IOError.FAILED(_("PDF file ")+@"$pdf_path"+_(" not found"));
			return pdf_path;
		}

		public PluginData get_data_object (string name) {
			return data_plugins2[name];
		}

		/**                                   **
		 * --- I M P L E M E N T A T I O N --- *
		 */                                 /**/

		Gee.HashMap<string, unowned PluginData> data_plugins2 = new Gee.HashMap<string, unowned PluginData>();
		Gee.HashMap<string, unowned PluginObject> object_plugins2 = new Gee.HashMap<string, unowned PluginObject>();
		TemplateList templates = new TemplateList ();
		static Gee.ArrayList<Plugins.Module> data_modules = new Gee.ArrayList<Plugins.Module>();
		static Gee.ArrayList<Plugins.Module> object_modules = new Gee.ArrayList<Plugins.Module>();
		Gee.HashMap<string, Gee.HashMap<string, AnswerValue>> requests;
		Glob document = null;
		Glob out_document = null;
		string[] objects_list = { };
		bool[] composed_objects = {};
		int last_template_index = -1;

		void load_templates_list () {
			var templates_strv = settings.templates;
			templates.clear ();
			foreach (var ts in templates_strv)
				add_template (ts);
		}

		void save_templates_list () {
			string[] templates_strv = {};
			foreach (var t in templates) {
				templates_strv += (t.get_path ());
			}
			settings.templates = templates_strv;
		}

		~Core () {
			AppDirs.terminate ();
		}

		PluginObject? find_plugin (string request, out string object_suffix, out string object_cmd) {
			object_suffix = null;
			object_cmd = null;
			var first_ = request.split_set(":?.", 2)[0];
			foreach (var p in object_plugins.entries) {
				if (first_.has_prefix (p.value.get_name())) {
					object_suffix = first_.substring (p.value.get_name().length);
					object_cmd = request.offset (first_.length + 1);
					return p.value;
				}
			}
			return null;
		}

		bool in_table (Queue<IDoc> doc_stack) {
			var len = doc_stack.length;
			return (len >= 6
			    && doc_stack.peek_nth(len - 6) is Table.ATable
			    && doc_stack.peek_nth(len - 5) is Table.Subtable
			    && doc_stack.peek_nth(len - 4) is Table.Row
			    && doc_stack.peek_nth(len - 3) is Table.Cell
			    && doc_stack.peek_nth(len - 2) is Glob
			    ) ? true : false;
		}

		bool check_for_addrows (Table.Cell cell, bool remove = false) {
			var ret = false;
			foreach (var doc in cell.contents)
				if (doc is Text) {
					var t = doc as Text;
					if (/#\baddrows\b/.match(t.text)) {
						if (remove) {
							t.text = t.text.replace("#addrows", "");
						}
						ret = true;
					}
				}
			return ret;
		}

		bool check_for_addcols (Table.Cell cell, out int max_cols, bool remove = false) {
			max_cols = 0;
			var ret = false;
			foreach (var doc in cell.contents)
				if (doc is Text) {
					var t = doc as Text;
					if (/\\#\baddcols\b/.match(t.text)) {
						try {
							var regex = new Regex ("\\\\#addcols\\\\#[0-9]+");
							MatchInfo match_info;
							regex.match (t.text, 0, out match_info);
							while (match_info.matches ()) {
								var word = match_info.fetch (0).substring(11);
								max_cols = int.max(max_cols, int.parse(word));
								match_info.next();
							}
							if (remove)
								t.text = regex.replace_literal (t.text, -1, 0, "");
						} catch (RegexError e) {}
						ret = true;
					}
				}
			return ret;
		}

		// current row contains #addrows => ++dimension
		bool row_has_addrows (Table.Row row) {
			foreach (var cell in row)
				if (check_for_addrows(cell))
							return true;
			return false;
		}

		bool row_has_addcols (Table.Row row, uint col_index) {
			uint index = 0;
			foreach (var cell in row) {
				if (index >= col_index)
					if (check_for_addcols(cell, null))
						return true;
					else
						return false;
				else
					index += cell.multitype == Table.Cell.Multitype.MULTICOL ? cell.ncells : 1;
			}
			return false;
		}

		bool subtable_has_addcols (Table.Subtable subtable, uint col_index) {
			foreach (var row in subtable)
				if (row_has_addcols (row, col_index)) return true;
			return false;
		}

		// one of 5 subtables contains #addcols in current column => ++dimension
		bool atable_has_addcols (Table.ATable table, Table.Row row, Table.Cell cell) {
			uint col_index = 0;
			foreach (var c in row) {
				if (cell == c) break;
				col_index += c.multitype == Table.Cell.Multitype.MULTICOL ? c.ncells : 1;
			}
			switch (table.get_type().name()) {
				case "LAviewTableTabular":
					if (subtable_has_addcols ((table as Table.Tabular).table, col_index)) return true;
					break;
				case "LAviewTableLongtable":
					var longtable = table as Table.Longtable;
					if (subtable_has_addcols (longtable.first_header, col_index)) return true;
					if (subtable_has_addcols (longtable.header, col_index)) return true;
					if (subtable_has_addcols (longtable.table, col_index)) return true;
					if (subtable_has_addcols (longtable.footer, col_index)) return true;
					if (subtable_has_addcols (longtable.last_footer, col_index)) return true;
					break;
			}
			return false;
		}

		enum Stage {
			ANALYSE,
			FILL
		}

		void resize_table (Table.ATable table, ResizeInfo resize_info) {
			Table.Subtable tables[] = { table.first_header, table.header, table.table,
			                            table.footer, table.last_footer };
			var ncols = table.params.size;
			int nrows = 0;
			foreach (var subtable in tables)
				if (nrows < subtable.size)
					nrows = subtable.size;


			var rowsvv_b = new bool[5,nrows]; // has #addrows
			var colsv_b = new bool[ncols];    // has #addcols
			resize_info.colsv_max = new int[ncols];   // cols per subtable when splitting

			for (var t = 0; t < 5; ++t) {
				for (var i = 0; i < tables[t].size; ++i) {
					for (uint j = 0, col_cnt = 0; j < tables[t][i].size; ++j) {
						var cell = tables[t][i][(int)j];

						if (check_for_addrows(cell)) {
							rowsvv_b[t,i] = true;
							check_for_addrows(cell, true);
						}

						int max_cols;
						if (check_for_addcols(cell, out max_cols)) {
							colsv_b[col_cnt] = true;
							resize_info.colsv_max[col_cnt] = max_cols;
							check_for_addcols(cell, null, true);
						}

						col_cnt += (   cell.multitype == Table.Cell.Multitype.MULTICOL
						            || cell.multitype == Table.Cell.Multitype.MULTICOLROW) ?
						           cell.ncells : 1;
					}
				}
			}

			resize_info.colsv = new int[ncols];       // X grow size
			resize_info.rowsvv = new int[5,nrows];    // Y grow size

			for (var t = 0; t < 5; ++t) {
				for (var i = 0; i < tables[t].size; ++i) {
					for (var j = 0; j < tables[t][i].size; ++j) {
						var cell = tables[t][i][j];

						foreach (var subdoc in cell.contents) {
							try {
								var regex = new Regex ("{\\[}[^][}{]*{\\]}");
								MatchInfo match_info;
								regex.match ((subdoc as Text).text, 0, out match_info);
								while (match_info.matches ()) {
									string object_suffix, object_cmd;
									var word = match_info.fetch (0);
									var request = word.substring (3, word.length - 6);
									var plugin = find_plugin (request, out object_suffix, out object_cmd);
									if (plugin == null) { match_info.next(); continue; }
									var req = requests[plugin.get_name() + object_suffix][object_cmd];
									if (req is AnswerArray1D) {
										if (rowsvv_b[t,i] && ! colsv_b[j])
											resize_info.rowsvv[t,i] = int.max(resize_info.rowsvv[t,i], (req as AnswerArray1D).value.length);
										else if (colsv_b[j] && !rowsvv_b[t,i])
											resize_info.colsv[j] = int.max(resize_info.colsv[j], (req as AnswerArray1D).value.length);
									} else if (req is AnswerArray2D) {
										if (colsv_b[j] && rowsvv_b[t,i]) {
											resize_info.rowsvv[t,i] = int.max(resize_info.rowsvv[t,i], (req as AnswerArray2D).value.length[0]);
											resize_info.colsv[j] = int.max(resize_info.colsv[j], (req as AnswerArray2D).value.length[1]);
										}
									}
									match_info.next();
								}
							} catch (RegexError e) {}
						}
					}
				}
			}

			// add cols
			for (int i = ncols - 1; i >= 0; --i)
				if (colsv_b[i])
					for (var j = 1; j < resize_info.colsv[i]; ++j)
						table.clone_col (i, i, true);

			// add rows
			for (var t = 0; t < 5; ++t)
				for (int r = tables[t].size; r >=0; --r)
					if (rowsvv_b[t, r])
						for (var j = 1; j < resize_info.rowsvv[t, r]; ++j)
							tables[t].insert(r, tables[t][r].copy() as Table.Row);
		}

		uint split_table (Glob glob, Table.ATable table, ResizeInfo resize_info) {
			try {
				var limits = new List<Table.ATable.SplitLimit?> ();
				if (resize_info.colsv.length != resize_info.colsv_max.length) return 1;
				uint f = 0, l = 0;
				for (var i = 0; i < resize_info.colsv.length; ++i) {
					var colsv_i = resize_info.colsv[i] == 0 ? 1 : resize_info.colsv[i];
					l = f + colsv_i - 1;
					if (f != l)
						limits.append(Table.ATable.SplitLimit()
						              { first = f, last = l, max_cols = resize_info.colsv_max[i] });
					f += colsv_i;
					l = f;
				}
				if (limits.length() != 0) {
					var delimiter = (table is Table.Tabular) ? "\\\\" : "";
					return table.split(glob, limits, delimiter);
				}
			} catch (Error e) {
			}
			return 1;
		}

		class ResizeInfo {
			public int[] colsv;
			public int[] colsv_max;
			public int[,] rowsvv;
		}

		// TODO #102:  get subtable, row, col indexes by doc_stack + resize_info
		void get_relative_indexes (Queue<IDoc> doc_stack, ResizeInfo resize_info, out int row_idx, out int col_idx) {
			row_idx = col_idx = 0;
			var subtable_idx = 0, ridx = 0, cidx = 0;

			var len = doc_stack.get_length();
			var c = doc_stack.peek_nth(len - 3);
			var r = doc_stack.peek_nth(len - 4);
			var s = doc_stack.peek_nth(len - 5);
			var tab = doc_stack.peek_nth(len - 6);

			if (!(c is Table.Cell && r is Table.Row && s is Table.Subtable)) return;

			var row = r as Table.Row;
			cidx = row.index_of(c as Table.Cell);
			var subtable = s as Table.Subtable;
			ridx = subtable.index_of(row);

			var atable = tab as Table.ATable;
			if (subtable == atable.first_header)
				subtable_idx = 0;
			else if (subtable == atable.header)
				subtable_idx = 1;
			else if (subtable == atable.table)
				subtable_idx = 2;
			else if (subtable == atable.footer)
				subtable_idx = 3;
			else if (subtable == atable.last_footer)
				subtable_idx = 4;

			for (int i = 0, sum = 0; i < resize_info.rowsvv.length[1]; ++i) {
				var rowsvv_i = resize_info.rowsvv[subtable_idx,i];
				if (rowsvv_i == 0) rowsvv_i = 1;
				if (ridx >= sum && ridx < sum + rowsvv_i) {
					row_idx = ridx - sum;
					break;
				} else {
					sum += rowsvv_i;
				}
			}
			for (int i = 0, sum = 0; i < resize_info.colsv.length; ++i) {
				var colsv_i = resize_info.colsv[i];
				if (colsv_i == 0) colsv_i = 1;
				if (cidx >= sum && cidx < sum + colsv_i) {
					col_idx = cidx - sum;
					break;
				} else {
					sum += colsv_i;
				}
			}
		}

		uint recursive_walk (Queue<IDoc> doc_stack,
		                                // Plugin name    // Object suffix
		                     Gee.HashMap<string, Gee.HashMap<string, AnswerValue>> requests,
		                     Stage stage, ResizeInfo? resize_info = null) {
		    uint ret = 1;
		    var doc = doc_stack.peek_tail ();
		    var stack_len = doc_stack.get_length();
			switch (doc.get_type().name()) {
			case "LAviewTableTabular":
				var tabular = doc as Table.Tabular;
				var resize_info_new = new ResizeInfo();
				if (stage == Stage.FILL) resize_table (tabular, resize_info_new);
				doc_stack.push_tail ((doc as Table.Tabular).table);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				if (stage == Stage.FILL && stack_len > 1)
					ret = split_table (doc_stack.peek_nth (stack_len - 2) as Glob, tabular, resize_info_new);
				break;
			case "LAviewTableLongtable":
				var longtable = doc as Table.Longtable;
				var resize_info_new = new ResizeInfo();
				if (stage == Stage.FILL) resize_table (longtable, resize_info_new);
				doc_stack.push_tail (longtable.first_header);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				doc_stack.push_tail (longtable.header);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				doc_stack.push_tail (longtable.table);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				doc_stack.push_tail (longtable.footer);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				doc_stack.push_tail (longtable.last_footer);
				recursive_walk (doc_stack, requests, stage, resize_info_new);
				doc_stack.pop_tail ();
				if (stage == Stage.FILL && stack_len > 1)
					ret = split_table (doc_stack.peek_nth (stack_len - 2) as Glob, longtable, resize_info_new);
				break;
			case "LAviewTableSubtable":
				doc_stack.push_tail ((doc as Table.Subtable).caption);
				recursive_walk (doc_stack, requests, stage, resize_info);
				doc_stack.pop_tail ();
				foreach (var subdoc in doc as Table.Subtable) {
					doc_stack.push_tail (subdoc);
					recursive_walk (doc_stack, requests, stage, resize_info);
					doc_stack.pop_tail ();
				}
				break;
			case "LAviewTableCell":
				doc_stack.push_tail ((doc as Table.Cell).contents);
				recursive_walk (doc_stack, requests, stage, resize_info);
				doc_stack.pop_tail ();
				break;
			case "LAviewGraphics":
					var path = (doc as Graphics).path;
					string object_suffix, object_cmd;
					var plugin = find_plugin (path, out object_suffix, out object_cmd);
					if (plugin == null) break;
				switch (stage) {
				case Stage.ANALYSE:
					if (!requests.has_key(plugin.get_name() + object_suffix))
						requests[plugin.get_name() + object_suffix] = new Gee.HashMap<string,AnswerValue>();
					requests[plugin.get_name() + object_suffix][object_cmd] = new AnswerString();
					break;
				case Stage.FILL:
					(doc as Graphics).path =
						(requests[plugin.get_name() + object_suffix][object_cmd] as AnswerString).value;
					break;
				}
				break;

			case "LAviewText":
				try {
					/* Replace requests with answers */
					var regex = new Regex ("{\\[}[^][}{]*{\\]}");
					MatchInfo match_info;
					regex.match ((doc as Text).text, 0, out match_info);
					var out_text = (doc as Text).text;

					while (match_info.matches ()) {
						var word = match_info.fetch (0);
						var request = word.substring (3, word.length - 6);

						// Find plugin which name conforms to request
						string object_suffix, object_cmd;
						var plugin = find_plugin (request, out object_suffix, out object_cmd);
						if (plugin == null) { match_info.next(); continue; }

						switch (stage) {
						case Stage.ANALYSE:
							AnswerValue answer;

							var dimension = 0;
							if (in_table(doc_stack)) {
								// Determine answer type (text, vector, matrix).
								dimension += row_has_addrows (doc_stack.peek_nth(doc_stack.length - 4) as Table.Row) ? 1 : 0;
								var len = doc_stack.length;
								var table = doc_stack.peek_nth(len - 6) as Table.ATable;
								var row = doc_stack.peek_nth(len - 4) as Table.Row;
								var cell = doc_stack.peek_nth(len - 3) as Table.Cell;
								dimension += atable_has_addcols (table, row, cell) ? 1 : 0;
							}
							switch (dimension) {
								case 1: answer = new AnswerArray1D(); break;
								case 2: answer = new AnswerArray2D(); break;
								default: answer = new AnswerString(); break;
							}
							if (!requests.has_key(plugin.get_name() + object_suffix))
								requests[plugin.get_name() + object_suffix] = new Gee.HashMap<string,AnswerValue>();
							requests[plugin.get_name() + object_suffix][object_cmd] = answer;
							break;
						case Stage.FILL:
							var answer = requests[plugin.get_name() + object_suffix].get(object_cmd);
							var dimension = 0;
							if (answer is AnswerArray1D) dimension = 1;
							if (answer is AnswerArray2D) dimension = 2;

							switch (dimension) {
								case 1: // Array 1D
									var arr = answer as AnswerArray1D;
									var row_idx = 0, col_idx = 0;
									get_relative_indexes(doc_stack, resize_info, out row_idx, out col_idx);
									var max_idx = int.max(row_idx, col_idx);
									if (max_idx < arr.value.length)
										out_text = arr.value[max_idx];
									else
										out_text = _("IdxError");
									break;
								case 2: // Array 2D
									var arr = answer as AnswerArray2D;
									var row_idx = 0, col_idx = 0;
									get_relative_indexes(doc_stack, resize_info, out row_idx, out col_idx);
									if (row_idx < arr.value.length[0] && col_idx < arr.value.length[1])
										out_text = arr.value[row_idx, col_idx];
									else
										out_text = _("IdxError");
									break;
								default: // Text/String
									out_text = out_text.replace("{[}"+request+"{]}", (answer as AnswerString).value);
								break;
							}
							break;
						}

						match_info.next();
					}

					/* Replace ViewName */
					regex = new Regex ("@LAview\\.ViewName=[^@]+@");
					regex.match (out_text, 0, out match_info);
					if (match_info.matches ()) {
						var word = match_info.fetch (0);
						out_text = out_text.replace(word, "");
					}

					(doc as Text).text = out_text ;
				} catch (RegexError e) {}
				break;
			default:
				if (doc is ADocList) {
					var d = doc as ADocList<IDoc>;
					for (var i = 0; i < d.size; ) {
						var subdoc = d[i];
						doc_stack.push_tail (subdoc);
						i += (int)recursive_walk (doc_stack, requests, stage, resize_info);
						doc_stack.pop_tail ();
					}
				}
				break;
			}
			return 1;
		}

		string doc_tex_path () {
			return  Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.cache_dir, "document.tex");
		}
		string doc_lyx_path () {
			return Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.cache_dir, "document.lyx");
		}
		string doc_pdf_path () {
			return  Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.cache_dir, "document.pdf");
		}
		void generate_document_tex () throws Error {
			if (document == null)
				throw new IOError.FAILED (_("Prepare document first."));
			var doc_stack = new Queue<IDoc> ();
			out_document = document.copy () as Glob;
			doc_stack.push_tail (out_document);
			recursive_walk (doc_stack, requests, Stage.FILL);
			FileUtils.set_contents (doc_tex_path (), out_document.generate ());
		}
		string generate_document_lyx () throws Error {
			generate_document_tex ();
			var converter = new Conv.Converter.new_with_paths (lyx_path, latexmk_pl_path, perl_path);
			var sp = converter.tex2lyx (doc_tex_path(), doc_lyx_path());
			if (sp.wait_check() == false) throw new IOError.FAILED(_("Error running tex2lyx subprocess."));
			if (!File.new_for_path(doc_lyx_path()).query_exists())
				throw new IOError.FAILED(_("Cann't create lyx document for editing."));
			return doc_lyx_path();
		}

		void clear_cache () throws Error {
			try {
				rm_rf (File.new_for_path (AppDirs.cache_dir));
			} catch (Error e) {
			}
			File.new_for_path (AppDirs.cache_dir).make_directory();
		}
	}
}
