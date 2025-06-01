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

let Hooks = {}

// whitespace-pre-line 첫 줄 개행 문제 해결 Hook
Hooks.FixWhitespace = {
  mounted() {
    this.fixWhitespace()
  },
  
  updated() {
    this.fixWhitespace()
  },
  
  fixWhitespace() {
    // 첫 번째 텍스트 노드 찾기
    const walker = document.createTreeWalker(
      this.el,
      NodeFilter.SHOW_TEXT,
      null,
      false
    )
    
    const firstTextNode = walker.nextNode()
    if (firstTextNode && firstTextNode.nodeValue) {
      // 첫 번째 텍스트 노드에서 시작 부분의 공백과 개행 제거
      const originalText = firstTextNode.nodeValue
      const trimmedText = originalText.replace(/^\s+/, '')
      
      if (originalText !== trimmedText) {
        console.log('Fixed whitespace:', {original: originalText, trimmed: trimmedText})
        firstTextNode.nodeValue = trimmedText
      }
    }
  }
}

// Manual file upload hook - bypasses Phoenix LiveView upload system
Hooks.ManualFileUpload = {
  mounted() {
    this.el.addEventListener("change", e => {
      console.log("Manual file input changed:", e.target.files)
      if (e.target.files.length > 0) {
        const file = e.target.files[0]
        console.log("Selected file:", file.name, file.size, file.type)
        
        // 파일 크기 체크 (10MB)
        if (file.size > 10 * 1024 * 1024) {
          alert("파일 크기가 10MB를 초과합니다.")
          return
        }
        
        // 파일 타입 체크
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
        if (!allowedTypes.includes(file.type)) {
          alert("지원하지 않는 파일 형식입니다. JPG, PNG, GIF, WEBP만 가능합니다.")
          return
        }
        
        // 파일을 Base64로 읽기
        const reader = new FileReader()
        reader.onload = (event) => {
          console.log("File read as base64, length:", event.target.result.length)
          
          // LiveView로 파일 데이터 전송
          this.pushEvent("file_selected", {
            file: {
              name: file.name,
              size: file.size,
              type: file.type,
              data: event.target.result
            }
          })
        }
        
        reader.onerror = (error) => {
          console.error("File read error:", error)
          alert("파일을 읽는 중 오류가 발생했습니다.")
        }
        
        reader.readAsDataURL(file)
      }
    })
  }
}

// Horizontal scroll hook for horizontal scrolling
Hooks.HorizontalScroll = {
  mounted() {
    // Add mouse wheel horizontal scrolling
    this.el.addEventListener("wheel", (e) => {
      if (e.deltaY !== 0) {
        e.preventDefault()
        this.el.scrollLeft += e.deltaY
      }
    })
    
    // Add touch/swipe support for mobile
    let touchStartX = 0
    let scrollStartX = 0
    
    this.el.addEventListener("touchstart", (e) => {
      touchStartX = e.touches[0].clientX
      scrollStartX = this.el.scrollLeft
    })
    
    this.el.addEventListener("touchmove", (e) => {
      e.preventDefault()
      const touchCurrentX = e.touches[0].clientX
      const touchDiffX = touchStartX - touchCurrentX
      this.el.scrollLeft = scrollStartX + touchDiffX
    })
  }
}

// Image modal hook for handling escape key
Hooks.ImageModal = {
  mounted() {
    // Handle escape key to close modal
    this.handleKeyDown = (e) => {
      if (e.key === "Escape") {
        this.pushEvent("hide_image_modal", {})
      }
    }
    
    document.addEventListener("keydown", this.handleKeyDown)
  },
  
  destroyed() {
    document.removeEventListener("keydown", this.handleKeyDown)
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
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

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
