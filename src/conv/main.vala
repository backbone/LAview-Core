/**
 * LaTeX view.
 *
 * Public system of data view in the LaTeX format.
 */
namespace LAview {

	/**
	 * LAview conversion methods.
	 *
	 * Supported formats: TeX, LyX, PDF, etc...
	 */
	namespace Conv {

		/**
		 * File format converter (lyx, tex, pdf).
		 */
		public class Converter : Object {
	        public string lyx_path { get; construct; }
	        public string latexmk_pl_path { get; construct; }
	        public string perl_path { get; construct; }

			/**
			 * Constructs a new ``Converter``.
			 */
			public Converter () { Object(lyx_path: "lyx", latexmk_pl_path: "latexmk", perl_path: "perl"); }
			public Converter.new_with_paths (string lyx_path, string latexmk_pl_path, string perl_path) {
				Object(lyx_path: lyx_path, latexmk_pl_path: latexmk_pl_path, perl_path: perl_path);
			}

			/**
			 * LyX->TeX conversion.
			 */
			public Subprocess lyx2tex (string lyx_file, string tex_path) throws Error {
			    /* check paths */
				if (!File.new_for_path(lyx_file).query_exists())
					throw new IOError.NOT_FOUND(_("File ")+lyx_file+_(" not found"));
				if (!File.new_for_path(tex_path).get_parent().query_exists())
					throw new IOError.NOT_FOUND(_("Target directory for ")+tex_path+_(" does not exists"));
				return (new SubprocessLauncher(  SubprocessFlags.STDIN_PIPE
				                               | SubprocessFlags.STDOUT_PIPE
				                               | SubprocessFlags.STDERR_PIPE))
				        .spawnv({ lyx_path, "-batch", "--force-overwrite", "all",
				                  "--export-to", "latex", tex_path, lyx_file });
			}

			/**
			 * TeX->LyX conversion.
			 */
			public Subprocess tex2lyx (string tex_file, string lyx_file_path) throws Error {
			    /* check paths */
				if (!File.new_for_path(tex_file).query_exists())
					throw new IOError.NOT_FOUND(_("File ")+tex_file+_(" not found"));
				if (!File.new_for_path(lyx_file_path).get_parent().query_exists())
					throw new IOError.NOT_FOUND(_("Target directory for ")+lyx_file_path+_(" does not exists"));
				var last_index_of = lyx_path.last_index_of ("lyx");
				if (last_index_of == -1) throw new IOError.NOT_FOUND(_("Cann't find tex2lyx command"));
				var tex2lyx_path = lyx_path.substring(0, last_index_of)
				                   + "tex2" + lyx_path.offset(last_index_of);
				return (new SubprocessLauncher(  SubprocessFlags.STDIN_PIPE
				                               | SubprocessFlags.STDOUT_PIPE
				                               | SubprocessFlags.STDERR_PIPE))
				        .spawnv({ tex2lyx_path, "-f", /*"-copyfiles",*/ tex_file, lyx_file_path });
			}

			/**
			 * LyX->PDF conversion.
			 */
			public Subprocess lyx2pdf (string lyx_file, string pdf_path) throws Error {
			    /* check paths */
				if (!File.new_for_path(lyx_file).query_exists())
					throw new IOError.NOT_FOUND(_("File ")+lyx_file+_(" not found"));
				if (!File.new_for_path(pdf_path).get_parent().query_exists())
					throw new IOError.NOT_FOUND(_("Target directory for ")+pdf_path+_(" does not exists"));
				return (new SubprocessLauncher(  SubprocessFlags.STDIN_PIPE
				                               | SubprocessFlags.STDOUT_PIPE
				                               | SubprocessFlags.STDERR_PIPE))
				        .spawnv({ lyx_path, "-batch", "--force-overwrite", "all",
				                  "--export-to", "pdf", pdf_path, lyx_file });
			}

			/**
			 * TeX->PDF conversion.
			 */
			public Subprocess tex2pdf (string tex_file, string pdf_path) throws Error {
			    /* check paths */
				if (!File.new_for_path(tex_file).query_exists())
					throw new IOError.NOT_FOUND(_("File ")+tex_file+_(" not found"));
				if (!File.new_for_path(pdf_path).get_parent().query_exists())
					throw new IOError.NOT_FOUND(_("Target directory for ")+pdf_path+_(" does not exists"));

				var pdf_dir = File.new_for_path(pdf_path).get_parent().get_path();
				var pdf_name = File.new_for_path(pdf_path).get_basename();
				pdf_name = /.pdf$/i.replace(pdf_name, -1, 0, "");

				var sl = new SubprocessLauncher(  SubprocessFlags.STDIN_PIPE
				                                | SubprocessFlags.STDOUT_PIPE
				                                | SubprocessFlags.STDERR_PIPE);
				sl.set_cwd(File.new_for_path(tex_file).get_parent().get_path());
			    #if (UNIX)
					return sl.spawnv({ "latexmk", "-output-directory="+pdf_dir,
					                   "-jobname="+pdf_name, "-pdf", tex_file });
				#elif (WINDOWS)
					return sl.spawnv({ perl_path, latexmk_pl_path, "-output-directory="+pdf_dir,
					                   "-jobname="+pdf_name, "-pdf", tex_file });
				#else
					assert_not_reached ();
				#endif
			}
		}
	}
}
