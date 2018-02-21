/**
 * System calls.
 */
namespace Get {
	/**
	 * Gets library path.
	 * @param so_path out path to shared library.
	 * @param addr initialization method source address.
	 */
	extern void library_path (string so_path, void *addr);
}

/**
 * LaTeX view.
 *
 * Public system of data view in the LaTeX format.
 */
namespace LAview.Core {

	/**
	 * Application directories/paths.
	 */
	class AppDirs {

		/**
		 * Shared library path.
		 */
		public static File so_path;

		/**
		 * Binary directory.
		 */
		public static File exec_dir;

		/**
		 * Common directory (parent to binary and shared).
		 */
		public static File common_dir;

		/**
		 * Data Plugins directory.
		 */
		public static string data_plugins_dir;

		/**
		 * Object Plugins directory.
		 */
		public static string object_plugins_dir;

		/**
		 * User Interface Glade files directory.
		 */
		public static string ui_dir;

		/**
		 * Settings/GLib Schemas directory.
		 */
		public static string settings_dir;

		/**
		 * Temporary directory.
		 */
		public static string temp_dir;

		/**
		 * Cache in temporary directory.
		 */
		public static string cache_dir;

		/**
		 * Initialization.
		 * @throws FileError file i/o error.
		 */
		public static void init () throws FileError {
			char _so_path[256];
			Get.library_path ((string)_so_path, (void*)init);
			so_path = File.new_for_path ((string)_so_path);
			exec_dir = so_path.get_parent ();
			common_dir = exec_dir.get_parent ();
			ui_dir = Path.build_path (Path.DIR_SEPARATOR_S, common_dir.get_path(),
			                          "share/laview-core-"+Config.VERSION_MAJOR.to_string()+"/ui");
			settings_dir = Path.build_path (Path.DIR_SEPARATOR_S, common_dir.get_path(), "share/glib-2.0/schemas");
			string w32dhack_sdir = settings_dir+"/laview-core-"+Config.VERSION_MAJOR.to_string();
			if (File.new_for_path(w32dhack_sdir+"/gschemas.compiled").query_exists ())
				settings_dir = w32dhack_sdir;
			data_plugins_dir = Path.build_path (Path.DIR_SEPARATOR_S, exec_dir.get_path(),
			                          "laview-core-"+Config.VERSION_MAJOR.to_string()+"/data-plugins");
			object_plugins_dir = Path.build_path (Path.DIR_SEPARATOR_S, exec_dir.get_path(),
			                          "laview-core-"+Config.VERSION_MAJOR.to_string()+"/object-plugins");
			temp_dir = DirUtils.make_tmp ("laview-core-XXXXXX.temp");
			cache_dir = Path.build_path (Path.DIR_SEPARATOR_S, AppDirs.temp_dir, "cache");
		}

		/**
		 * Termination.
		 * @throws Error any error.
		 */
		public static void terminate () throws Error {
			rm_rf (File.new_for_path(temp_dir));
		}
	}
}
