const copyButton = document.querySelector('#copy-install');
const installCommand = document.querySelector('#install-command');
const copyStatus = document.querySelector('#copy-status');

copyButton?.addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText(installCommand.textContent.trim());
    copyStatus.textContent = 'Copied to clipboard.';
    copyButton.textContent = 'Copied';
    window.setTimeout(() => {
      copyStatus.textContent = '';
      copyButton.textContent = 'Copy command';
    }, 2200);
  } catch {
    copyStatus.textContent = 'Select the command and copy it manually.';
  }
});
