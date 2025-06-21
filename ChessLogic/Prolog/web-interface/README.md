# Chess Web Interface

A beautiful web interface for your Prolog chess game with real-time gameplay, AI opponent, and interactive board.

## Features

- 🎮 **Interactive Chess Board**: Click to select pieces and see legal moves highlighted in green
- 🤖 **AI Opponent**: Play against your Prolog-based chess AI
- 🎨 **Beautiful UI**: Modern gradient design with smooth animations
- ♻️ **Game Controls**: New game, undo moves, bot moves, and refresh
- 📝 **Game Log**: Real-time logging of all game events
- ⚡ **Responsive**: Works on desktop and mobile devices
- ⌨️ **Keyboard Shortcuts**: Ctrl+R (refresh), Ctrl+N (new game), Ctrl+Z (undo)

## Setup Instructions

### Prerequisites

1. **SWI-Prolog**: Make sure SWI-Prolog is installed and `swipl` command is available in your PATH
2. **Node.js**: Install Node.js (version 14 or higher)

### Installation

1. **Navigate to the web interface directory**:

   ```bash
   cd "d:/Github/CoVua/ChessLogic/Prolog/web-interface"
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

3. **Start the server**:

   ```bash
   npm start
   ```

4. **Open your browser** and go to:
   ```
   http://localhost:3000
   ```

## How to Play

### Basic Gameplay

1. **New Game**: Click "🔄 New Game" to start a fresh game
2. **Select Piece**: Click on any of your pieces (white pieces if you're human)
3. **See Legal Moves**: Legal moves will be highlighted in green with dots
4. **Make Move**: Click on any green square to move your piece there
5. **Bot Move**: Click "🤖 Bot Move" or wait for the AI to move automatically

### Game Controls

- **🔄 New Game**: Reset the board to starting position
- **🤖 Bot Move**: Force the AI to make its move
- **↶ Undo**: Undo the last move (if possible)
- **🔍 Refresh**: Refresh the board state from Prolog

### Visual Indicators

- **Yellow Square**: Currently selected piece
- **Green Squares**: Legal moves for the selected piece
- **Animated Squares**: Recent moves are briefly highlighted

## File Structure

```
web-interface/
├── package.json          # Node.js dependencies
├── server.js            # Express server + Prolog bridge
├── public/
│   ├── index.html       # Main web page
│   ├── style.css        # Beautiful styling
│   └── script.js        # Chess game logic
└── README.md           # This file
```

## API Endpoints

The server provides these endpoints for communication with Prolog:

- `POST /init` - Initialize a new game
- `GET /position` - Get current board position
- `POST /pick` - Select a piece and get legal moves
- `POST /place` - Make a move
- `POST /bot` - Make AI move
- `GET /status` - Get game status
- `POST /reset` - Reset the game
- `POST /undo` - Undo last move

## Troubleshooting

### Common Issues

1. **"Failed to start Prolog" error**:

   - Make sure SWI-Prolog is installed
   - Verify `swipl` command works in terminal
   - Check that your Prolog files are in the correct directory

2. **"Prolog execution failed" error**:

   - Check the server console for detailed error messages
   - Verify your Prolog files have no syntax errors
   - Make sure all required predicates exist

3. **Board not updating**:

   - Click "🔍 Refresh" to force a board update
   - Check the game log for error messages
   - Verify the server is running

4. **Legal moves not showing**:
   - Make sure you're clicking on your own pieces
   - Check if it's your turn (current turn is displayed)
   - Try refreshing the board

### Debug Mode

To see detailed logs:

1. Open browser Developer Tools (F12)
2. Go to Console tab
3. All game events and errors will be logged there

### Server Logs

The Node.js server logs all Prolog queries and responses. Check the terminal where you started the server for detailed information.

## Development

### Adding New Features

1. **Prolog Side**: Add new predicates to your chess.pl files
2. **Server Side**: Add new API endpoints in server.js
3. **Client Side**: Add UI controls and JavaScript functions

### Customization

- **Styling**: Modify `public/style.css` for visual changes
- **Game Logic**: Update `public/script.js` for client-side behavior
- **AI Difficulty**: Change the depth setting in your Prolog files

## Keyboard Shortcuts

- **Ctrl + R**: Refresh board
- **Ctrl + N**: New game
- **Ctrl + Z**: Undo move

## Browser Compatibility

- Chrome/Edge: Full support
- Firefox: Full support
- Safari: Full support
- Mobile browsers: Responsive design

## Performance Notes

- The interface automatically shows a loading spinner during AI moves
- Board updates are optimized to only redraw when necessary
- Game log is limited to prevent memory issues

Enjoy your chess game! ♔♛
