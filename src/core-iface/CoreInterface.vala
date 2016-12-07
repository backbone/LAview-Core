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
		 */
		public abstract bool compose (Object parent, Gee.HashMap<string, AnswerValue> answers) throws Error;
	}

	/**
	 * Request Answer Value.
	 */
	public abstract class AnswerValue : Object {
	}

	/**
	 * String.
	 */
	public class AnswerString : AnswerValue {
		public string value;

		public AnswerString (string value = "") {
			this.value = value;
		}
	}

	/**
	 * 1D Array.
	 */
	public class AnswerArray1D : AnswerValue {
		public string[] value;
	}

	/**
	 * 2D Array;
	 */
	public class AnswerArray2D : AnswerValue {
		public string[,] value;
	}

	/**
	 * Picture Buffer (Currently path (String) is enough).
	 */
	/*public class AnswerPicBuffer : AnswerValue {
	}*/
}
