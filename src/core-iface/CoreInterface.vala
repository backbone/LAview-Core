using GObject.Plugins;

/**
 * LaTeX view.
 *
 * Public system of data view in the LaTeX format.
 */
namespace LAview.Core {

	/**
	 * Core Host Interface.
	 */
	public interface IHostCore : IHost {

		/**
		 * Get cache directory path.
		 */
		public abstract string get_cache_dir ();

		/**
		 * Get data object.
		 * @param name data object name.
		 */
		public abstract PluginData get_data_object (string name);
	}

	/**
	 * Abstract plugin of type Data.
	 */
	public abstract class PluginData: Plugin {

		/**
		 * Get Plugin name.
		 */
		public abstract string get_name ();

		/**
		 * Get Plugin readable name.
		 */
		public abstract string get_readable_name ();

		/**
		 * Open Preferences.
		 */
		public abstract void preferences (Object parent) throws Error;
	}

	/**
	 * Abstract plugin of type Protocol.
	 */
	public abstract class PluginObject : Plugin {

		/**
		 * Get Plugin name.
		 */
		public abstract string get_name ();

		/**
		 * Get Plugin readable name.
		 */
		public abstract string get_readable_name ();

		/**
		 * Compose the object.
		 * @param parent parent Object/Window.
		 * @param answers answers values.
		 * @throws Error any compose error.
		 */
		public abstract bool compose (Object parent, Gee.HashMap<string, AnswerValue> answers) throws Error;

		/**
		 * Open Preferences.
		 */
		public abstract void preferences (Object parent) throws Error;
	}

	/**
	 * Request Answer Value.
	 */
	public abstract class AnswerValue : Object {
		/**
		 * Constructs a new ``AnswerValue``.
		 */
		public AnswerValue () { }
	}

	/**
	 * String Answer.
	 */
	public class AnswerString : AnswerValue {
		/**
		 * String value.
		 */
		public string value;

		/**
		 * Constructs a new ``AnswerString``.
		 * @param value string value.
		 */
		public AnswerString (string value = "") {
			this.value = value;
		}
	}

	/**
	 * 1D Array Answer.
	 */
	public class AnswerArray1D : AnswerValue {
		/**
		 * Array value.
		 */
		public string[] value;

		/**
		 * Constructs a new ``AnswerArray1D``.
		 */
		public AnswerArray1D () { }
	}

	/**
	 * 2D Array Answer;
	 */
	public class AnswerArray2D : AnswerValue {
		/**
		 * Array value.
		 */
		public string[,] value;

		/**
		 * Constructs a new ``AnswerArray1D``.
		 */
		public AnswerArray2D () { }
	}

	/**
	 * Picture Buffer (Currently path (String) is enough).
	 */
	/*public class AnswerPicBuffer : AnswerValue {
	}*/
}
