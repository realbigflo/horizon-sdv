
document.addEventListener('DOMContentLoaded', () => {
    const themeToggle = document.getElementById('theme-toggle');
    const body = document.body;
    const icon = themeToggle.querySelector('i');

    // Check for saved theme preference
    const savedTheme = localStorage.getItem('theme') || 'dark';
    body.className = savedTheme;
    updateIcon();

    themeToggle.addEventListener('click', () => {
        body.classList.toggle('dark');
        const currentTheme = body.classList.contains('dark') ? 'dark' : 'light';
        localStorage.setItem('theme', currentTheme);
        updateIcon();
    });

    function updateIcon() {
        const isDark = body.classList.contains('dark');
        icon.className = isDark ? 'bx bx-sun' : 'bx bx-moon';
    }
});
