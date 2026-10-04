class Cairn < Formula
  desc "Shared handoff ledger and coordination protocol for coding agents"
  homepage "https://github.com/mcclements02/cairn"
  url "https://github.com/mcclements02/cairn/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "05b6b599dee1cb53d03390bfd61e31d0a1d8e80073b107a85260a4573660a2a6"
  license "MIT"
  head "https://github.com/mcclements02/cairn.git", branch: "main"

  depends_on "bash"
  depends_on "git"
  depends_on "perl"

  def install
    inreplace "cairn", "#!/usr/bin/env bash", "#!#{Formula["bash"].opt_bin}/bash"
    libexec.install "cairn", "templates", "VERSION"
    bin.install_symlink libexec/"cairn"
  end

  test do
    assert_match "cairn init", shell_output("#{bin}/cairn help")
    assert_match(/\Acairn \d+\.\d+\.\d+\n\z/, shell_output("#{bin}/cairn --version"))
    system "git", "init", "--quiet", testpath
    system bin/"cairn", "init", "--entry-file", "agent-instructions.md", testpath
    assert_path_exists testpath/"AI_HANDOFF.md"
    assert_match "CAIRN-ENTRY:BEGIN", (testpath/"agent-instructions.md").read
    assert_match "in sync", shell_output("#{bin}/cairn check #{testpath}")
    (testpath/"scripts/cairn-check.sh").write "deliberate drift\n"
    assert_match "DRIFT", shell_output("#{bin}/cairn check #{testpath}", 1)
  end
end
