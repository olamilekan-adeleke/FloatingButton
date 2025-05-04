import UIKit
//import PlaygroundSupport
import SwiftUI

// MARK: - Models

enum RecordingState {
    case stopped
    case recording
    case paused
    case none
}

// MARK: - Delegate Protocol

protocol RecordingControlsDelegate: AnyObject {
    func recordingControlsDidPause()
    func recordingControlsDidResume()
    func recordingControlsDidStop()
}

// MARK: - Implementation for SwiftUI
class RecordingControlsViewModel: ObservableObject {
    @Published var currentState: RecordingState = .recording
    weak var delegate: RecordingControlsDelegate?
    
    func togglePauseResume() {
        if currentState == .paused {
            currentState = .recording
            delegate?.recordingControlsDidResume()
        } else if currentState == .recording {
            currentState = .paused
            delegate?.recordingControlsDidPause()
        }
    }
    
    func stop() {
        currentState = .stopped
        delegate?.recordingControlsDidStop()
    }
}

// MARK: - View Components
struct RecordingIndicator: View {
    let state: RecordingState
    @Binding var isBlinking: Bool
    
    var body: some View {
        Circle()
            .fill(state == .paused ? Color.gray : Color.red)
            .frame(width: 8, height: 8)
            .opacity(state == .recording && isBlinking ? 1 : 0.2)
            .animation(
                state == .recording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                value: isBlinking
            )
            .padding(4)
            .background(Circle().fill(Color.white))
    }
}

struct ControlButton: View {
    let action: () -> Void
    let content: AnyView
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> some View) {
        self.action = action
        self.content = AnyView(content())
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 32, height: 32)
                content
            }
        }
    }
}

// MARK: - Main View

struct FloatingRecordingControls: View {
    @StateObject private var viewModel = RecordingControlsViewModel()
    @State private var isCircleVisible: Bool = true
    @State private var isTextVisible: Bool = true
    
    private let textVisibilityTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    init(delegate: RecordingControlsDelegate? = nil) {
        // TODO: might want to improve this, dont know for now
        _viewModel = StateObject(wrappedValue: {
            let vm = RecordingControlsViewModel()
            vm.delegate = delegate
            return vm
        }())
    }
    
    var body: some View {
        HStack(spacing: 15) {
            if viewModel.currentState != .stopped {
                recordingStatusView
            }
            
            controlButtons
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.currentState)
    }
    
    // MARK: - Subviews
    
    private var recordingStatusView: some View {
        HStack(spacing: 8) {
            RecordingIndicator(state: viewModel.currentState, isBlinking: $isCircleVisible)
                .onAppear(perform: startBlinkingIfRecording)
                .onChange(of: viewModel.currentState) { newState in
                    if newState == .recording {
                        withAnimation { isCircleVisible.toggle() }
                    }
                }
            
            if isTextVisible {
                Text("Taking notes")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .scale))
                    .onReceive(textVisibilityTimer) { _ in
                        withAnimation(.easeOut(duration: 1.0)) { isTextVisible = false }
                    }
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 15) {
            if viewModel.currentState != .stopped {
                pauseResumeButton
            }
            
            stopButton
        }
    }
    
    private var pauseResumeButton: some View {
        ControlButton(action: viewModel.togglePauseResume) {
            if viewModel.currentState == .recording {
                Image(systemName: "pause.fill").foregroundColor(Color.white).frame(width: 10, height: 14)
            } else {
                Image(systemName: "play.fill").foregroundColor(Color.white).frame(width: 10, height: 14)
            }
        }
    }
    
    private var stopButton: some View {
        ControlButton(action: viewModel.stop) {
            Rectangle().fill(Color.white).frame(width: 14, height: 14)
        }
    }
    
    private func startBlinkingIfRecording() {
        if viewModel.currentState == .recording {
            withAnimation { isCircleVisible.toggle() }
        }
    }
}

// MARK: - Example Delegate Implementation
class RecordingManager: RecordingControlsDelegate {
    func recordingControlsDidPause() {
        print("Recording paused")
    }
    
    func recordingControlsDidResume() {
        print("Recording resumed")
    }
    
    func recordingControlsDidStop() {
        print("Recording stopped")
    }
}

// MARK: - Previews
struct FloatingRecordingControls_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
            FloatingRecordingControls()
        }.previewDisplayName("Default (Recording)")
    }
}

// MARK: - Content View
struct ContentView: View {
    private let recordingManager = RecordingManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.edgesIgnoringSafeArea(.all)
            FloatingRecordingControls(delegate: recordingManager).padding(.top, 60)
        }
    }
}

// MARK: - Playground Setup
//let hostingController = UIHostingController(rootView: ContentView())
//hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
//
//PlaygroundPage.current.liveView = hostingController

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

#Preview {
    ContentView()
}
