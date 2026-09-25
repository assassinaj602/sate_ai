// SATE AI Documentation & Landing Page Interaction Scripts

function copyCode(btn) {
  const codeBox = btn.closest('.code-box');
  if (!codeBox) return;
  const codeEl = codeBox.querySelector('code');
  if (!codeEl) return;

  const textToCopy = codeEl.innerText.trim();
  navigator.clipboard.writeText(textToCopy).then(() => {
    const originalText = btn.innerText;
    btn.innerText = "Copied!";
    btn.style.color = "var(--pass)";
    btn.style.borderColor = "var(--pass)";
    setTimeout(() => {
      btn.innerText = originalText;
      btn.style.color = "";
      btn.style.borderColor = "";
    }, 2000);
  }).catch(err => {
    console.error('Failed to copy text: ', err);
  });
}

function copyInstallation() {
  const copyBtn = document.getElementById("copy-btn");
  if (copyBtn) {
    copyCode(copyBtn);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;
      const targetEl = document.querySelector(targetId);
      if (targetEl) {
        e.preventDefault();
        targetEl.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });

  // LocalStorage Theme Persistence
  const savedTheme = localStorage.getItem('sate-theme');
  if (savedTheme) {
    document.body.setAttribute('data-theme', savedTheme);
  }
});
