using GObject, Plugins;

/**
 * LaTeX view.
 *
 * Public system of data view in the LaTeX format.
 */
namespace LAview.Core {

	/**
	 * Template Interface.
	 */
	public abstract interface ITemplate : Object {
		public abstract string get_readable_name ();
		public abstract string get_path ();
		public abstract bool is_equal_to (ITemplate template);
	}

	/**
	 * LyX File Template.
	 */
	public class LyxTemplate : Object, ITemplate {

		File file;
		string _readable_name = null;

		public LyxTemplate (string file) {
			this.file = File.new_for_path (file);
		}

		public string get_readable_name () {
			if (_readable_name == null) {
				string contents;

				try {
					FileUtils.get_contents (file.get_path(), out contents);

					var regex = new Regex ("@LAview\\.ViewName=[^@]+@");
					MatchInfo match_info;
					regex.match (contents, 0, out match_info);

					if (match_info.matches ()) {
						var word = match_info.fetch (0);
						_readable_name = word.substring(17, word.length - 17 - 1).strip();
					}
				} catch (Error e) {
					_readable_name = file.get_basename();
				}
			}

			return _readable_name;
		}

		public bool is_equal_to (ITemplate template) {
			if (template is LyxTemplate)
				return (template as LyxTemplate).file.get_path() == file.get_path();

			return false;
		}

		public string get_path () { return file.get_path(); }
	}

	/**
	 * LyX File Template.
	 */
	public class TexTemplate : Object, ITemplate {

		File file;

		public TexTemplate (string file) {
			this.file = File.new_for_path (file);
		}

		public string get_readable_name () {
			return file.get_basename();
		}

		public bool is_equal_to (ITemplate template) {
			if (template is TexTemplate)
				return (template as TexTemplate).file.get_path() == file.get_path();

			return false;
		}

		public string get_path () { return file.get_path(); }
	}

	public class TemplateList : Gee.ArrayList<ITemplate> {
		public override bool contains (ITemplate template) {
			foreach (var t in this)
				if (t.is_equal_to (template))
					return true;
			return false;
		}
	}
}
