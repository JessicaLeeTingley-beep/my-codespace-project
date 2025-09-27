// My Codespace Project JavaScript

function sayHello() {
    const messageDiv = document.getElementById('message');
    const messages = [
        'Hello from your Codespace! 👋',
        'Codespaces are awesome! 🌟',
        'Happy coding in the cloud! ☁️',
        'VS Code in your browser! 💻',
        'GitHub Codespaces rocks! 🚀'
    ];
    
    const randomMessage = messages[Math.floor(Math.random() * messages.length)];
    
    messageDiv.textContent = randomMessage;
    messageDiv.className = 'success';
    
    // Add some animation
    messageDiv.style.opacity = '0';
    setTimeout(() => {
        messageDiv.style.transition = 'opacity 0.5s ease-in-out';
        messageDiv.style.opacity = '1';
    }, 100);
}

// Welcome message when page loads
window.addEventListener('load', () => {
    console.log('🎉 Welcome to your GitHub Codespace project!');
    console.log('🔧 Ready for development!');
});