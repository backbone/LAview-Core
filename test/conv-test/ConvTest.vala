/**
 * LyX->PDF test
 */
void lyx2pdf_test (string[] args) {
	Subprocess sp = null;
	try {
		sp = (new LAview.Conv.Converter()).lyx2pdf(Path.build_path (Path.DIR_SEPARATOR_S,
		        File.new_for_path(args[0]).get_parent().get_parent().get_parent().get_path(),
		        "test/conv-test/templates/templ_ex1.lyx"), "templ_ex1.pdf");

		if (sp.wait_check() == false) throw new IOError.FAILED("Error running subprocess.");

		stdout.puts("=== Converting LyX->PDF... ===\n");
		var ds_out = new DataInputStream(sp.get_stdout_pipe());
		try {
			for (string s = ds_out.read_line(); s != null; s = ds_out.read_line())
				stdout.printf("%s\n", s);
		} catch (IOError err) {
			assert_not_reached();
		}
	} catch (Error err) {
		stdout.printf("Error: %s\n", err.message);
		if (sp != null) {
			var ds_err = new DataInputStream(sp.get_stderr_pipe());
			try {
				for (string s = ds_err.read_line(); s != null; s = ds_err.read_line())
					stdout.printf("%s\n", s);
			} catch (IOError err) {
				assert_not_reached();
			}
		}
	}
}

/**
 * LyX->TeX test
 */
void lyx2tex_test (string[] args) {
	Subprocess sp = null;
	try {
		sp = (new LAview.Conv.Converter()).lyx2tex(Path.build_path (Path.DIR_SEPARATOR_S,
		        File.new_for_path(args[0]).get_parent().get_parent().get_parent().get_path(),
		        "test/conv-test/templates/templ_ex1.lyx"), "templ_ex1.tex");

		if (sp.wait_check() == false) throw new IOError.FAILED("Error running subprocess.");

		stdout.puts("=== Converting LyX->TeX... ===\n");
		var ds_out = new DataInputStream(sp.get_stdout_pipe());
		try {
			for (string s = ds_out.read_line(); s != null; s = ds_out.read_line())
				stdout.printf("%s\n", s);
		} catch (IOError err) {
			assert_not_reached();
		}
	} catch (Error err) {
		stdout.printf("Error: %s\n", err.message);
		if (sp != null) {
			var ds_err = new DataInputStream(sp.get_stderr_pipe());
			try {
				for (string s = ds_err.read_line(); s != null; s = ds_err.read_line())
					stdout.printf("%s\n", s);
			} catch (IOError err) {
				assert_not_reached();
			}
		}
	}
}

/**
 * TeX->PDF test
 */
void tex2pdf_test (string[] args) {
	Subprocess sp = null;
	try {
		sp = (new LAview.Conv.Converter()).tex2pdf("templ_ex1.tex", "templ_ex1.latexmk.pdf");

		if (sp.wait_check() == false) throw new IOError.FAILED("Error running subprocess.");

		stdout.puts("=== Converting TeX->PDF... ===\n");
		var ds_out = new DataInputStream(sp.get_stdout_pipe());
		try {
			for (string s = ds_out.read_line(); s != null; s = ds_out.read_line())
				stdout.printf("%s\n", s);
		} catch (IOError err) {
			assert_not_reached();
		}
	} catch (Error err) {
		stdout.printf("Error: %s\n", err.message);
		if (sp != null) {
			var ds_err = new DataInputStream(sp.get_stderr_pipe());
			try {
				for (string s = ds_err.read_line(); s != null; s = ds_err.read_line())
					stdout.printf("%s\n", s);
			} catch (IOError err) {
				assert_not_reached();
			}
		}
	}
}


void main(string[] args) {
	lyx2pdf_test(args);
	lyx2tex_test(args);
	tex2pdf_test(args);
}
