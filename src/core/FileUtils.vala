namespace LAview.Core {
	void rm_rf (File directory) throws Error {
		var children = directory.enumerate_children ("standard::*",
		        FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
		FileInfo fileinfo = null;
		while ((fileinfo = children.next_file (null)) != null ) {
			File child = directory.resolve_relative_path (fileinfo.get_name ());
			if (fileinfo.get_file_type () == FileType.DIRECTORY) {
				rm_rf (child);
			} else {
				child.delete();
			}
		}
		directory.delete();
	}
}
