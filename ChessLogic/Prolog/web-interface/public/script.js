class ChessGame {
    constructor() {
        this.selectedSquare = null;
        this.legalMoves = [];
        this.currentTurn = 'white';
        this.position = null;
        this.moveCount = 0;
        this.gameStatus = 'Game in progress';
        this.capturedPieces = { white: [], black: [] };
        
        // Chess piece Unicode symbols
        this.pieceSymbols = {
            // White pieces (your system uses lowercase for some representation)
            'white': {
                'pawn': '♙', 'rook': '♖', 'knight': '♘', 
                'bishop': '♗', 'queen': '♕', 'king': '♔'
            },
            // Black pieces
            'black': {
                'pawn': '♟', 'rook': '♜', 'knight': '♞',
                'bishop': '♝', 'queen': '♛', 'king': '♚'
            }
        };
        
        this.initBoard();
        this.initGame();
    }
    
    initBoard() {
        const board = document.getElementById('chessboard');
        board.innerHTML = '';
        
        // Create 64 squares (8x8 board, 0-63 indexing)
        for (let i = 0; i < 64; i++) {
            const square = document.createElement('button');
            
            // Calculate if square should be light or dark
            const row = Math.floor(i / 8);
            const col = i % 8;
            const isLight = (row + col) % 2 === 0;
            
            square.className = `square ${isLight ? 'white-square' : 'black-square'}`;
            square.id = `square-${i}`;
            square.onclick = () => this.onSquareClick(i);
            
            // Add coordinate labels for debugging
            const file = String.fromCharCode(97 + col); // a-h
            const rank = 8 - row; // 8-1 (displayed from white's perspective)
            square.title = `${file}${rank} (${i})`;
            
            board.appendChild(square);
        }
    }
    
    async initGame() {
        this.showLoading(true);
        try {
            const response = await fetch('/init', { method: 'POST' });
            const result = await response.json();
            
            if (result.success) {
                this.log('Game initialized successfully');
                this.currentTurn = 'white';
                this.moveCount = 0;
                this.gameStatus = 'Game in progress';
                this.capturedPieces = { white: [], black: [] };
                await this.refreshBoard();
                this.updateDisplay();
            } else {
                this.log('Error initializing game: ' + result.error);
            }
        } catch (error) {
            this.log('Network error during initialization: ' + error.message);
        } finally {
            this.showLoading(false);
        }
    }
    
    async refreshBoard() {
        try {
            const response = await fetch('/position');
            const result = await response.json();
            
            if (result.success) {
                this.updateBoardDisplay(result.data);
            } else {
                this.log('Error getting position: ' + result.error);
            }
        } catch (error) {
            this.log('Network error while refreshing: ' + error.message);
        }
    }    updateBoardDisplay(positionData) {
        // Clear all squares first
        for (let i = 0; i < 64; i++) {
            const square = document.getElementById(`square-${i}`);
            square.textContent = '';
            square.classList.remove('piece-white', 'piece-black');
        }
        
        this.log('Raw position data: ' + positionData);
        
        // Parse the position data from Prolog
        // Expected format: [[white_pieces],[black_pieces]]
        try {
            this.parsePrologPosition(positionData);
        } catch (error) {
            this.log('Error parsing position: ' + error.message);
        }
    }    parsePrologPosition(data) {
        try {
            this.log('=== DEBUG: Parsing position data ===');
            this.log('Raw data: ' + JSON.stringify(data));
            
            // Parse position: [[white_pieces],[black_pieces]]
            // where each piece list is [pawns, rooks, knights, bishops, queens, kings]
            const position = this.parseNestedList(data);
            this.log('Parsed position: ' + JSON.stringify(position));
            
            if (position && position.length === 2) {
                const whitePieces = position[0];  // [pawns, rooks, knights, bishops, queens, kings]
                const blackPieces = position[1];  // [pawns, rooks, knights, bishops, queens, kings]
                
                this.log('White pieces: ' + JSON.stringify(whitePieces));
                this.log('Black pieces: ' + JSON.stringify(blackPieces));
                
                this.placePiecesOnBoard(whitePieces, 'white');
                this.placePiecesOnBoard(blackPieces, 'black');
                
                this.updateDisplay();
            } else {
                throw new Error('Position data does not contain 2 arrays');
            }
            
        } catch (error) {
            this.log('Error parsing position: ' + error.message + ' | Data: ' + data);
            // Fallback to initial position for testing
            this.placeInitialPieces();
        }
    }    parseNestedList(listString) {
        try {
            this.log('Parsing nested list: ' + listString);
            
            // Handle Prolog list format and convert to JavaScript
            let normalized = listString.trim();
            
            // If it's already in a format we can parse, try JSON first
            if (normalized.startsWith('[') && normalized.endsWith(']')) {
                try {
                    // First try direct JSON parsing
                    const result = JSON.parse(normalized);
                    this.log('JSON parse successful!');
                    return result;
                } catch (e) {
                    this.log('JSON parse failed: ' + e.message + ', trying Prolog parsing...');
                }
            }
            
            // Manual Prolog list parsing
            // Convert Prolog list format to JSON
            // Handle formats like: [[1,2],[3,4]] where numbers aren't quoted
            let jsonString = normalized;
            
            // Try to fix common Prolog format issues
            // This is a simple approach - we'll improve it based on actual data
            if (jsonString.includes('[') && !jsonString.includes('"')) {
                this.log('Attempting basic Prolog format conversion...');
                // For now, if it looks like valid array syntax, try to parse it
                try {
                    // Most Prolog numeric lists should parse as valid JavaScript
                    const result = eval('(' + jsonString + ')');
                    if (Array.isArray(result)) {
                        this.log('Prolog format conversion successful!');
                        return result;
                    }
                } catch (evalError) {
                    this.log('Eval failed: ' + evalError.message);
                }
            }
            
            this.log('All parsing attempts failed for: ' + listString);
            return null;
            
        } catch (error) {
            this.log('Error parsing nested list: ' + error.message);
            return null;
        }
    }
    
    placePiecesOnBoard(pieceLists, color) {
        if (!pieceLists || pieceLists.length !== 6) {
            this.log(`Invalid piece lists for ${color}: expected 6 lists, got ${pieceLists ? pieceLists.length : 'null'}`);
            return;
        }
        
        const pieceTypes = ['pawn', 'rook', 'knight', 'bishop', 'queen', 'king'];
        
        for (let i = 0; i < 6; i++) {
            const positions = pieceLists[i];
            const pieceType = pieceTypes[i];
            
            if (Array.isArray(positions)) {
                positions.forEach(pos => {
                    this.placePieceAt(pos, pieceType, color);
                });
            }
        }
    }
      placePieceAt(position, pieceType, color) {
        const square = document.getElementById(`square-${position}`);
        if (square) {
            const symbol = this.pieceSymbols[color][pieceType];
            square.textContent = symbol;
            square.classList.add(`piece-${color}`);
        }
    }
    
    placeInitialPieces() {
        // Place initial chess position for testing
        // White pieces
        const whiteBack = [0, 1, 2, 3, 4, 5, 6, 7];
        const whitePawns = [8, 9, 10, 11, 12, 13, 14, 15];
        const whitePieces = ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'];
        
        // Black pieces  
        const blackBack = [56, 57, 58, 59, 60, 61, 62, 63];
        const blackPawns = [48, 49, 50, 51, 52, 53, 54, 55];
        const blackPieces = ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'];
        
        // Place white pieces
        whiteBack.forEach((pos, index) => {
            const square = document.getElementById(`square-${pos}`);
            square.textContent = whitePieces[index];
            square.classList.add('piece-white');
        });
        
        whitePawns.forEach(pos => {
            const square = document.getElementById(`square-${pos}`);
            square.textContent = '♙';
            square.classList.add('piece-white');
        });
        
        // Place black pieces
        blackBack.forEach((pos, index) => {
            const square = document.getElementById(`square-${pos}`);
            square.textContent = blackPieces[index];
            square.classList.add('piece-black');
        });
        
        blackPawns.forEach(pos => {
            const square = document.getElementById(`square-${pos}`);
            square.textContent = '♟';
            square.classList.add('piece-black');
        });
    }
    
    async onSquareClick(pos) {
        if (this.selectedSquare === null) {
            // First click - try to select piece
            await this.selectPiece(pos);
        } else if (this.legalMoves.includes(pos)) {
            // Second click on legal move - make the move
            await this.makeMove(this.selectedSquare, pos);
        } else {
            // Click elsewhere - deselect and try to select new piece
            this.clearSelection();
            await this.selectPiece(pos);
        }
    }
    
    async selectPiece(pos) {
        this.showLoading(true);
        try {
            const response = await fetch('/pick', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ pos })
            });
            
            const result = await response.json();
              if (result.success) {
                const movesData = result.legalMoves;
                this.log(`Raw legal moves data: "${movesData}"`);
                this.legalMoves = this.parseLegalMoves(movesData);
                
                if (this.legalMoves.length > 0) {
                    this.selectedSquare = pos;
                    this.highlightMoves();
                    this.log(`Selected piece at ${pos}, legal moves: [${this.legalMoves.join(', ')}]`);
                } else {
                    this.log(`No legal moves for piece at ${pos} (parsed from: "${movesData}")`);
                    this.clearSelection();
                }
            } else {
                this.log('Error selecting piece: ' + result.error);
                this.clearSelection();
            }
        } catch (error) {
            this.log('Network error during piece selection: ' + error.message);
        } finally {
            this.showLoading(false);
        }
    }    parseLegalMoves(movesString) {
        // Parse Prolog list format
        // Handle formats like "[]", "[1,2,3]", "[1, 2, 3]", or other variations
        
        this.log('Parsing legal moves: ' + movesString);
        
        if (!movesString || movesString === '[]' || movesString.trim() === '') {
            this.log('Empty or null legal moves');
            return [];
        }
        
        try {
            // Clean up the string first
            let cleanString = movesString.trim();
            
            // Handle Prolog canonical format: remove any extra whitespace and normalize
            cleanString = cleanString.replace(/\s+/g, '');
            
            // Try direct JSON parsing first for simple cases like [1,2,3]
            if (cleanString.startsWith('[') && cleanString.endsWith(']') && !cleanString.includes('(')) {
                try {
                    const result = JSON.parse(cleanString);
                    this.log('JSON parse successful: [' + result.join(', ') + ']');
                    return result;
                } catch (e) {
                    this.log('JSON parse failed: ' + e.message + ', trying regex approach');
                }
            }
            
            // Extract all numbers from the string (handles any Prolog format)
            const matches = cleanString.match(/\d+/g);
            const result = matches ? matches.map(Number) : [];
            
            this.log('Regex parse result: [' + result.join(', ') + ']');
            return result;
            
        } catch (error) {
            this.log('Error parsing legal moves: ' + error.message);
            return [];
        }
    }
    
    highlightMoves() {
        // Clear previous highlights
        this.clearHighlights();
        
        // Highlight selected square
        if (this.selectedSquare !== null) {
            const selectedEl = document.getElementById(`square-${this.selectedSquare}`);
            if (selectedEl) {
                selectedEl.classList.add('selected');
            }
        }
        
        // Highlight legal moves in green
        this.legalMoves.forEach(move => {
            const square = document.getElementById(`square-${move}`);
            if (square) {
                square.classList.add('legal-move');
            }
        });
    }
      async makeMove(from, to) {
        this.showLoading(true);
        try {
            this.log(`Attempting move: ${from} → ${to}`);
            
            const response = await fetch('/place', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ from, to })
            });
            
            const result = await response.json();
            this.log(`Move response: ${JSON.stringify(result)}`);
            
            if (result.success) {
                this.log(`Move executed: ${from} → ${to}`);
                this.clearSelection();
                this.moveCount++;
                
                // Add visual feedback for the move
                this.animateMove(from, to);
                
                // Refresh the board to show the new position
                await this.refreshBoard();
                
                // Update game status
                await this.updateGameStatus();
                
                // Update display
                this.updateDisplay();
                
            } else {
                this.log('Error making move: ' + result.error);
                // Clear selection if move failed
                this.clearSelection();
            }
        } catch (error) {
            this.log('Network error during move: ' + error.message);
            this.clearSelection();
        } finally {
            this.showLoading(false);
        }
    }
    
    animateMove(from, to) {
        const fromSquare = document.getElementById(`square-${from}`);
        const toSquare = document.getElementById(`square-${to}`);
        
        if (fromSquare && toSquare) {
            fromSquare.classList.add('moving');
            toSquare.classList.add('moving');
            
            setTimeout(() => {
                fromSquare.classList.remove('moving');
                toSquare.classList.remove('moving');
            }, 500);
        }
    }
    
    async updateGameStatus() {
        try {
            const response = await fetch('/status');
            const result = await response.json();
            
            if (result.success) {
                this.gameStatus = result.status || 'Game in progress';
            }
        } catch (error) {
            this.log('Error updating game status: ' + error.message);
        }
    }
    
    clearSelection() {
        this.selectedSquare = null;
        this.legalMoves = [];
        this.clearHighlights();
    }
    
    clearHighlights() {
        document.querySelectorAll('.square').forEach(square => {
            square.classList.remove('selected', 'legal-move');
        });
    }
    
    updateDisplay() {
        // Update turn indicator
        const turnElement = document.getElementById('current-turn');
        if (turnElement) {
            turnElement.textContent = this.currentTurn.charAt(0).toUpperCase() + this.currentTurn.slice(1);
            turnElement.className = `turn-color ${this.currentTurn}`;
        }
        
        // Update move counter
        const moveElement = document.getElementById('move-counter');
        if (moveElement) {
            moveElement.textContent = Math.floor(this.moveCount / 2) + 1;
        }
        
        // Update game status
        const statusElement = document.getElementById('game-status');
        if (statusElement) {
            statusElement.textContent = this.gameStatus;
        }
        
        // Enable/disable bot button based on turn
        const botBtn = document.getElementById('bot-btn');
        if (botBtn) {
            botBtn.disabled = this.currentTurn === 'white'; // Assuming human is white
        }
    }
    
    showLoading(show) {
        const loading = document.getElementById('loading');
        if (loading) {
            loading.classList.toggle('hidden', !show);
        }
    }
    
    log(message) {
        const logContent = document.getElementById('gameLog');
        if (logContent) {
            const timestamp = new Date().toLocaleTimeString();
            const logEntry = document.createElement('div');
            logEntry.className = 'log-entry';
            logEntry.innerHTML = `<span class="log-timestamp">${timestamp}</span>${message}`;
            logContent.appendChild(logEntry);
            logContent.scrollTop = logContent.scrollHeight;
        }
        console.log(`[Chess] ${message}`);
    }
}

// Global functions for UI buttons
async function initGame() {
    if (window.game) {
        await window.game.initGame();
    }
}

async function makeBotMove() {
    if (!window.game) return;
    
    window.game.showLoading(true);
    try {
        const response = await fetch('/bot', { method: 'POST' });
        const result = await response.json();
        
        if (result.success) {
            // Log the move details
            if (result.move) {
                const moveText = `🤖 Bot moved from ${result.move.from} to ${result.move.to}`;
                window.game.log(moveText);
                
                // Log the game status
                if (result.status) {
                    const statusText = result.status.toUpperCase();
                    let statusEmoji = '';
                    switch(result.status.toLowerCase()) {
                        case 'check': statusEmoji = '⚠️'; break;
                        case 'checkmate': statusEmoji = '🏁'; break;
                        case 'stalemate': statusEmoji = '�'; break;
                        case 'draw': statusEmoji = '🤝'; break;
                        case 'safe': statusEmoji = '✅'; break;
                        default: statusEmoji = 'ℹ️';
                    }
                    window.game.log(`${statusEmoji} Game status: ${statusText}`);
                }
            } else {
                window.game.log('�🤖 Bot move completed');
            }
            
            // Refresh the board and update game state
            await window.game.refreshBoard();
            await window.game.updateGameStatus();
            window.game.moveCount++;
            window.game.currentTurn = 'white'; // Assuming bot is black
            window.game.updateDisplay();
            
            // Debug output
            if (result.raw_output) {
                console.log('Bot move raw output:', result.raw_output);
            }
        } else {
            window.game.log('❌ Bot move failed: ' + (result.error || 'Unknown error'));
            if (result.raw_output) {
                console.log('Bot move failure output:', result.raw_output);
            }
        }
    } catch (error) {
        window.game.log('❌ Network error during bot move: ' + error.message);
        console.error('Bot move network error:', error);
    } finally {
        window.game.showLoading(false);
    }
}

async function refreshBoard() {
    if (window.game) {
        await window.game.refreshBoard();
        window.game.log('🔄 Board refreshed');
    }
}

async function undoMove() {
    if (!window.game) return;
    
    window.game.showLoading(true);
    try {
        const response = await fetch('/undo', { method: 'POST' });
        const result = await response.json();
        
        if (result.success) {
            window.game.log('↶ Move undone');
            await window.game.refreshBoard();
            window.game.moveCount = Math.max(0, window.game.moveCount - 1);
            window.game.currentTurn = window.game.currentTurn === 'white' ? 'black' : 'white';
            window.game.updateDisplay();
        } else {
            window.game.log('❌ Cannot undo: ' + result.error);
        }
    } catch (error) {
        window.game.log('❌ Network error during undo: ' + error.message);
    } finally {
        window.game.showLoading(false);
    }
}

async function resetGame() {
    if (!window.game) return;
    
    window.game.showLoading(true);
    try {
        const response = await fetch('/reset', { method: 'POST' });
        const result = await response.json();
        
        if (result.success) {
            window.game.log('🔄 Game reset');
            await window.game.refreshBoard();
            window.game.moveCount = 0;
            window.game.currentTurn = 'white';
            window.game.gameStatus = 'Game in progress';
            window.game.updateDisplay();
        } else {
            window.game.log('❌ Reset failed: ' + result.error);
        }
    } catch (error) {
        window.game.log('❌ Network error during reset: ' + error.message);
    } finally {
        window.game.showLoading(false);
    }
}

function clearLog() {
    const logContent = document.getElementById('gameLog');
    if (logContent) {
        logContent.innerHTML = '';
    }
}

// Initialize the game when page loads
window.addEventListener('DOMContentLoaded', () => {
    window.game = new ChessGame();
    
    // Add keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        if (e.key === 'r' && e.ctrlKey) {
            e.preventDefault();
            refreshBoard();
        } else if (e.key === 'n' && e.ctrlKey) {
            e.preventDefault();
            initGame();
        } else if (e.key === 'z' && e.ctrlKey) {
            e.preventDefault();
            undoMove();
        }
    });
    
    console.log('♔ Chess game interface loaded successfully! ♛');
    console.log('Keyboard shortcuts:');
    console.log('  Ctrl+R: Refresh board');
    console.log('  Ctrl+N: New game');
    console.log('  Ctrl+Z: Undo move');
});
