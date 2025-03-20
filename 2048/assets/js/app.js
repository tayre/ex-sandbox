// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Function to convert UTC timestamps to local time
function convertTimestampsToLocalTime() {
  document.querySelectorAll('.local-time').forEach(el => {
    const utcTime = el.getAttribute('data-utc');
    if (utcTime) {
      const date = new Date(utcTime + 'Z'); // Add Z to ensure UTC interpretation
      const localTimeStr = date.toLocaleString([], { 
        month: 'numeric', 
        day: 'numeric', 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: false
      });
      el.textContent = localTimeStr;
    }
  });
}

// Add to window load event
window.addEventListener('DOMContentLoaded', () => {
  convertTimestampsToLocalTime();
  
  // Check if we're on a mobile device
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  if (isMobile) {
    // Add a class to the body to enable mobile-specific CSS
    document.body.classList.add('mobile-device');
  }
});

// Add swipe gesture support for mobile
let Hooks = {}

// Function to determine the current path prefix
function getPathPrefix() {
  const path = window.location.pathname;
  if (path.startsWith('/2048')) {
    return '/2048';
  }
  return '';
}

// Get the correct WebSocket protocol based on the page protocol
function getSocketProtocol() {
  return window.location.protocol === 'https:' ? 'wss://' : 'ws://';
}

Hooks.GameBoard = {
  mounted() {
    let touchStartX, touchStartY;
    const MIN_SWIPE_DISTANCE = 20;
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    
    // Enable swipe gestures on mobile devices
    
    // Track animation completion
    this.handleEvent("animation_complete", () => {});
    
    // Touch start event
    this.el.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      
      // Prevent default within the game board to avoid page scrolling during swipes
      if (e.target.closest('.game-board-container')) {
        e.preventDefault();
      }
    }, { passive: false });
    
    // Touch end event
    this.el.addEventListener('touchend', (e) => {
      if (!touchStartX || !touchStartY) return;
      
      const touchEndX = e.changedTouches[0].clientX;
      const touchEndY = e.changedTouches[0].clientY;
      
      const diffX = touchStartX - touchEndX;
      const diffY = touchStartY - touchEndY;
      
      // Process swipes regardless of where they end
      // Determine if it's a horizontal or vertical swipe
      if (Math.abs(diffX) > Math.abs(diffY)) {
        // Horizontal swipe
        if (Math.abs(diffX) > MIN_SWIPE_DISTANCE) {
          if (diffX > 0) {
            // Swipe left
            this.pushEvent('move', { direction: 'left' });
          } else {
            // Swipe right
            this.pushEvent('move', { direction: 'right' });
          }
        }
      } else {
        // Vertical swipe
        if (Math.abs(diffY) > MIN_SWIPE_DISTANCE) {
          if (diffY > 0) {
            // Swipe up
            this.pushEvent('move', { direction: 'up' });
          } else {
            // Swipe down
            this.pushEvent('move', { direction: 'down' });
          }
        }
      }
      
      // Reset touch coordinates
      touchStartX = null;
      touchStartY = null;
    }, { passive: true });
    
    // Prevent default scrolling during touchmove only on the game board
    this.el.addEventListener('touchmove', (e) => {
      // Always prevent default within the game board itself to ensure no scrolling occurs
      if (e.target.closest('.game-board-container')) {
        e.preventDefault();
      }
    }, { passive: false });
    
    // Notify the LiveView that the animation has completed
    this.el.addEventListener('animationend', () => {
      this.pushEvent('animation_complete', {});
    });
  }
};

Hooks.LocalTime = {
  mounted() {
    this.updateTimes();
  },
  updated() {
    this.updateTimes();
  },
  updateTimes() {
    const timeElements = this.el.querySelectorAll('.local-time');
    timeElements.forEach(el => {
      const utcTime = el.getAttribute('data-utc');
      if (utcTime) {
        const date = new Date(utcTime + 'Z');
        // Format: 3/20, 4:36 PM
        const options = { 
          month: 'numeric', 
          day: 'numeric',
          hour: 'numeric', 
          minute: '2-digit',
          hour12: true
        };
        el.innerHTML = date.toLocaleString([], options);
      }
    });
  }
};

// Hook to expose win function to console
Hooks.WinFunction = {
  mounted() {
    // Expose the win function to the global scope
    window.win = () => {
      this.pushEvent('force_win', {});
    };
    
    // Expose the lost function to the global scope
    window.lost = () => {
      this.pushEvent('force_lose', {});
    };
    
    // Listen for when the game is won to trigger confetti effects
    this.handleEvent('game_won', () => {
      this.addExtraConfetti();
    });
  },
  
  // Add extra confetti for more celebration
  addExtraConfetti() {
    const container = document.querySelector('#fullscreen-confetti');
    if (container) {
      // Add 30 more confetti pieces dynamically
      for (let i = 0; i < 50; i++) {
        const confetti = document.createElement('div');
        confetti.className = 'confetti';
        confetti.style.left = `${Math.random() * 100}%`;
        confetti.style.animationDelay = `${Math.random() * 3}s`;
        confetti.style.opacity = `${0.5 + Math.random() * 0.5}`;
        
        // Completely randomize size within a small range (2-6px)
        const size = 2 + Math.random() * 4;
        
        // Randomize shape
        if (Math.random() > 0.6) {
          // Circle
          confetti.style.borderRadius = '50%';
          confetti.style.width = `${size}px`;
          confetti.style.height = `${size}px`;
        } else if (Math.random() > 0.6) {
          // Rectangle
          confetti.style.width = `${size * 0.7}px`;
          confetti.style.height = `${size * 1.5}px`;
        } else {
          // Square
          confetti.style.width = `${size}px`;
          confetti.style.height = `${size}px`;
        }
        
        // Random colors
        const colors = ['#f00', '#0f0', '#00f', '#ff0', '#f0f', '#0ff', '#ff8800', '#8800ff'];
        confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
        
        container.appendChild(confetti);
      }
    }
  }
};

// Simplified approach - use the default path for LiveSocket
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Disable LiveView debug logs in the console
liveSocket.disableDebug()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

