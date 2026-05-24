//
//  ContentView.swift
//  Swift Pong
//
//  Created by Sebastián Jasso  on 19/05/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {

    enum Screen {
        case menu
        case solo
        case oneVsOne
        case history
    }

    struct MatchRecord: Identifiable, Codable {
        let id: UUID
        let mode: String
        let leftScore: Int
        let rightScore: Int
        let date: Date
    }

    // Pantalla

    @State private var currentScreen: Screen = .menu
    @State private var matchHistory: [MatchRecord] = []

    // Pelota

    @State private var ballPosition = CGPoint(x: 200, y: 300)
    @State private var ballVelocity = CGSize(width: 4, height: 4)

    // Barras

    @State private var leftPaddleX: CGFloat = 200
    @State private var rightPaddleX: CGFloat = 200

    // Puntajes

    @State private var leftScore = 0
    @State private var rightScore = 0

    // Juego

    @State private var gameStarted = false

    // Audio

    @State private var effectPlayer: AVAudioPlayer?
    @State private var musicPlayer: AVAudioPlayer?

    // Tamaños

    let paddleWidth: CGFloat = 120
    let paddleHeight: CGFloat = 20
    let ballSize: CGFloat = 25
    let paddleEdgeInset: CGFloat = 90
    let matchHistoryKey = "matchHistory"

    var body: some View {

        GeometryReader { geometry in

            TimelineView(.animation) { timeline in

                Canvas { context, size in

                    if currentScreen != .menu && currentScreen != .history && gameStarted {
                        DispatchQueue.main.async {
                            updateGame(size: size)
                        }
                    }

                    // Fondo
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(Color(red: 0.01, green: 0.01, blue: 0.04))
                    )

                    // Línea central
                    var centerLine = Path()
                    centerLine.move(to: CGPoint(x: 0, y: size.height / 2))
                    centerLine.addLine(to: CGPoint(x: size.width, y: size.height / 2))

                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: .cyan.opacity(0.9), radius: 12))
                        layer.stroke(
                            centerLine,
                            with: .color(.cyan.opacity(0.55)),
                            lineWidth: 4
                        )
                    }

                    context.stroke(
                        centerLine,
                        with: .color(.white.opacity(0.45)),
                        lineWidth: 2
                    )

                    // Barra superior
                    let leftRect = CGRect(
                        x: leftPaddleX - paddleWidth / 2,
                        y: paddleEdgeInset,
                        width: paddleWidth,
                        height: paddleHeight
                    )

                    let leftPath = Path(roundedRect: leftRect, cornerRadius: 10)

                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: .cyan.opacity(0.95), radius: 16))
                        layer.fill(leftPath, with: .color(.cyan))
                    }

                    context.fill(leftPath, with: .color(Color(red: 0.0, green: 0.75, blue: 1.0)))
                    context.stroke(leftPath, with: .color(.white.opacity(0.85)), lineWidth: 1.5)

                    // Barra inferior
                    let rightRect = CGRect(
                        x: rightPaddleX - paddleWidth / 2,
                        y: size.height - paddleEdgeInset - paddleHeight,
                        width: paddleWidth,
                        height: paddleHeight
                    )

                    let rightPath = Path(roundedRect: rightRect, cornerRadius: 10)

                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: .pink.opacity(0.95), radius: 16))
                        layer.fill(rightPath, with: .color(.pink))
                    }

                    context.fill(rightPath, with: .color(Color(red: 1.0, green: 0.05, blue: 0.35)))
                    context.stroke(rightPath, with: .color(.white.opacity(0.85)), lineWidth: 1.5)

                    // Pelota
                    let ballRect = CGRect(
                        x: ballPosition.x,
                        y: ballPosition.y,
                        width: ballSize,
                        height: ballSize
                    )

                    let ballPath = Path(ellipseIn: ballRect)

                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: .white.opacity(0.95), radius: 18))
                        layer.fill(ballPath, with: .color(.white))
                    }

                    context.fill(ballPath, with: .color(.white))
                }
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in

                        guard currentScreen == .oneVsOne || currentScreen == .solo else { return }

                        let halfPaddle = paddleWidth / 2
                        let clampedX = min(
                            max(value.location.x, halfPaddle),
                            geometry.size.width - halfPaddle
                        )

                        if currentScreen == .solo {
                            rightPaddleX = clampedX
                        } else if value.location.y < geometry.size.height / 2 {
                            leftPaddleX = clampedX
                        } else {
                            rightPaddleX = clampedX
                        }
                    }
            )
            .overlay {

                ZStack {

                    switch currentScreen {
                    case .menu:
                        mainMenu
                    case .solo:
                        soloOverlay
                    case .oneVsOne:
                        oneVsOneOverlay
                    case .history:
                        historyMenu
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
        }
    }

    var mainMenu: some View {

        VStack(spacing: 18) {

            Text("SWIFT PONG")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .cyan, radius: 14)

            Button("JUGAR CONTRA IA") {
                startGame(screen: .solo)
            }
            .padding()
            .frame(width: 240)
            .background(Color.cyan.opacity(0.22))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyan, lineWidth: 2)
            )
            .shadow(color: .cyan.opacity(0.8), radius: 12)

            Button("1 VS 1") {
                startGame(screen: .oneVsOne)
            }
            .padding()
            .frame(width: 240)
            .background(Color.green.opacity(0.22))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green, lineWidth: 2)
            )
            .shadow(color: .green.opacity(0.8), radius: 12)

            Button("HISTORIAL") {
                currentScreen = .history
            }
            .padding()
            .frame(width: 240)
            .background(Color.purple.opacity(0.22))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.purple, lineWidth: 2)
            )
            .shadow(color: .purple.opacity(0.8), radius: 12)
        }
    }

    var soloOverlay: some View {

        ZStack {

            VStack {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SISTEMA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan, radius: 8)

                        Text("\(leftScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .cyan, radius: 10)
                    }

                    Spacer()

                    Button("MENÚ") {
                        returnToMenu()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: .cyan.opacity(0.55), radius: 8)
                }
                .padding(.top, paddleEdgeInset + paddleHeight + 16)

                Spacer()

                HStack {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("JUGADOR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .shadow(color: .pink, radius: 8)

                        Text("\(rightScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .pink, radius: 10)
                    }
                }
                .padding(.bottom, paddleEdgeInset + paddleHeight + 16)
            }
            .padding(.horizontal)

            if !gameStarted {

                VStack(spacing: 20) {

                    Text("SOLITARIO")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 14)

                    Button("INICIAR RONDA") {
                        startRound()
                    }
                    .padding()
                    .frame(width: 220)
                    .background(Color.green.opacity(0.22))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green, lineWidth: 2)
                    )
                    .shadow(color: .green.opacity(0.8), radius: 12)
                }
            }
        }
    }

    var oneVsOneOverlay: some View {

        ZStack {

            VStack {

                HStack {
                    Text("\(leftScore)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 10)

                    Spacer()

                    Button("MENÚ") {
                        returnToMenu()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: .cyan.opacity(0.55), radius: 8)
                }
                .padding(.top, paddleEdgeInset + paddleHeight + 16)

                Spacer()

                HStack {
                    Spacer()

                    Text("\(rightScore)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .pink, radius: 10)
                }
                .padding(.bottom, paddleEdgeInset + paddleHeight + 16)
            }
            .padding(.horizontal)

            if !gameStarted {

                VStack(spacing: 20) {

                    Text("1 VS 1")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 14)

                    Button("INICIAR RONDA") {
                        startRound()
                    }
                    .padding()
                    .frame(width: 220)
                    .background(Color.green.opacity(0.22))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green, lineWidth: 2)
                    )
                    .shadow(color: .green.opacity(0.8), radius: 12)
                }
            }
        }
    }

    var historyMenu: some View {

        VStack(spacing: 20) {

            Text("HISTORIAL")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .purple, radius: 14)

            if matchHistory.isEmpty {
                Text("SIN PARTIDAS GUARDADAS")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.75))
                    .shadow(color: .purple, radius: 8)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(matchHistory) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(record.mode)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(formatDate(record.date))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.75))
                                }

                                HStack {
                                    Text("AZUL: \(record.leftScore)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.cyan)
                                        .shadow(color: .cyan, radius: 6)

                                    Spacer()

                                    Text("ROJO: \(record.rightScore)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                        .shadow(color: .pink, radius: 6)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: .purple.opacity(0.45), radius: 10)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(width: 310, height: 280)
            }

            Button("VOLVER") {
                currentScreen = .menu
            }
            .padding()
            .frame(width: 220)
            .background(Color.gray.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.35), radius: 8)
        }
    }

    // Actualizar juego

    func updateGame(size: CGSize) {

        guard gameStarted else { return }

        ballPosition.x += ballVelocity.width
        ballPosition.y += ballVelocity.height

        if currentScreen == .solo {
            updateSystemPaddle(size: size)
        }

        // Rebote izquierda y derecha
        if ballPosition.x <= 0 || ballPosition.x >= size.width - ballSize {
            ballVelocity.width *= -1
            playSound(name: "bounce")
        }

        // Colisión superior
        if ballPosition.y <= paddleEdgeInset + paddleHeight &&
            ballPosition.y + ballSize >= paddleEdgeInset {

            if ballPosition.x > leftPaddleX - paddleWidth / 2 &&
                ballPosition.x < leftPaddleX + paddleWidth / 2 {

                ballVelocity.height *= -1
                playSound(name: "bounce")
            }
        }

        // Colisión inferior
        let bottomPaddleY = size.height - paddleEdgeInset - paddleHeight

        if ballPosition.y + ballSize >= bottomPaddleY &&
            ballPosition.y <= bottomPaddleY + paddleHeight {

            if ballPosition.x > rightPaddleX - paddleWidth / 2 &&
                ballPosition.x < rightPaddleX + paddleWidth / 2 {

                ballVelocity.height *= -1
                playSound(name: "bounce")
            }
        }

        // Punto inferior
        if ballPosition.y < paddleEdgeInset - ballSize {
            rightScore += 1
            resetBall(size: size)
            gameStarted = false
            playSound(name: "score")
        }

        // Punto superior
        if ballPosition.y > size.height - paddleEdgeInset {
            leftScore += 1
            resetBall(size: size)
            gameStarted = false
            playSound(name: "score")
        }
    }

    // MARK: - Sistema modo solitario

    func updateSystemPaddle(size: CGSize) {

        let targetX = ballPosition.x + ballSize / 2
        let distance = targetX - leftPaddleX
        let systemSpeed: CGFloat = 3.5
        let movement = min(max(distance, -systemSpeed), systemSpeed)
        let halfPaddle = paddleWidth / 2

        leftPaddleX = min(
            max(leftPaddleX + movement, halfPaddle),
            size.width - halfPaddle
        )
    }

    // MARK: - Navegación del juego

    func startGame(screen: Screen) {

        resetCurrentScore()
        gameStarted = false
        currentScreen = screen
    }

    func returnToMenu() {

        saveCurrentMatch()
        gameStarted = false
        currentScreen = .menu
    }

    func resetCurrentScore() {

        leftScore = 0
        rightScore = 0
    }

    // MARK: - Iniciar ronda

    func startRound() {

        gameStarted = true

        if musicPlayer?.isPlaying != true {
            playMusic()
        }
    }

    // MARK: - Reiniciar pelota

    func resetBall(size: CGSize) {

        ballPosition = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        ballVelocity.height *= -1
    }

    // MARK: - Sonidos

    func playSound(name: String) {

        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }

        do {
            effectPlayer = try AVAudioPlayer(contentsOf: url)
            effectPlayer?.play()
        } catch {
            print("Error reproduciendo sonido")
        }
    }

    // MARK: - Música

    func playMusic() {

        guard let url = Bundle.main.url(forResource: "music", withExtension: "mp3") else {
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.3
            musicPlayer?.play()
        } catch {
            print("Error reproduciendo música")
        }
    }

    // MARK: - Historial

    func saveCurrentMatch() {

        guard leftScore > 0 || rightScore > 0 else { return }

        let mode = currentScreen == .solo ? "Solitario" : "1 vs 1"
        let record = MatchRecord(
            id: UUID(),
            mode: mode,
            leftScore: leftScore,
            rightScore: rightScore,
            date: Date()
        )

        matchHistory.insert(record, at: 0)
        saveHistory()
    }

    func saveHistory() {

        do {
            let data = try JSONEncoder().encode(matchHistory)
            UserDefaults.standard.set(data, forKey: matchHistoryKey)
        } catch {
            print("Error guardando historial")
        }
    }

    func loadHistory() {

        guard let data = UserDefaults.standard.data(forKey: matchHistoryKey) else {
            return
        }

        do {
            matchHistory = try JSONDecoder().decode([MatchRecord].self, from: data)
        } catch {
            print("Error cargando historial")
        }
    }

    func formatDate(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}
#Preview {
    ContentView()
}
