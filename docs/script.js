function copyInstallation() {
  const codeText = "dependencies:\n  sate_ai: ^0.7.0";
  navigator.clipboard.writeText(codeText).then(() => {
    const btn = document.getElementById("copy-btn");
    if (btn) {
      const originalText = btn.innerText;
      btn.innerText = "Copied!";
      btn.style.color = "#3b82f6";
      btn.style.borderColor = "#3b82f6";
      setTimeout(() => {
        btn.innerText = originalText;
        btn.style.color = "";
        btn.style.borderColor = "";
      }, 2000);
    }
  });
}
