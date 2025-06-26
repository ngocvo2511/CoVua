const express = require('express');
const cors = require('cors');
const { spawn, execSync } = require('child_process');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Path to your Prolog files
const PROLOG_PATH = path.join(__dirname, '..');

// Function to find SWI-Prolog executable
function findSwiProlog() {
    const possiblePaths = [
        'swipl',           // Standard PATH
        'swipl.exe',       // Windows with .exe
        'D:\\Program Files\\swipl\\bin\\swipl.exe',  // Common Windows install
        'D:\\Program Files (x86)\\swipl\\bin\\swipl.exe', // 32-bit on 64-bit Windows
        'D:\\swipl\\bin\\swipl.exe',  // Alternative Windows install
        '/usr/bin/swipl',  // Linux/Mac
        '/usr/local/bin/swipl'  // Alternative Linux/Mac
    ];
    
    const { execSync } = require('child_process');
    
    for (const path of possiblePaths) {
        try {
            // Test if this path works
            execSync(`"${path}" --version`, { stdio: 'ignore', timeout: 5000 });
            console.log(`Found SWI-Prolog at: ${path}`);
            return path;
        } catch (error) {
            // This path doesn't work, try next
            continue;
        }
    }
    
    throw new Error('SWI-Prolog not found. Please install SWI-Prolog or add it to your PATH.');
}

// Global Prolog process
let prologProcess = null;
let queryQueue = [];
let processingQuery = false;

// Function to start persistent Prolog process
function startPrologProcess() {
    if (prologProcess) {
        return; // Already running
    }

    let swiPath;
    try {
        swiPath = findSwiProlog();
    } catch (error) {
        throw error;
    }

    console.log('Starting persistent Prolog process...');
    prologProcess = spawn(swiPath, [
        '-q',           // Quiet mode
        '-s', 'chess.pl'  // Load chess.pl script
    ], {
        cwd: PROLOG_PATH,
        stdio: ['pipe', 'pipe', 'pipe'],
        shell: false
    });

    prologProcess.on('error', (err) => {
        console.error('Prolog process error:', err);
        prologProcess = null;
    });

    prologProcess.on('close', (code) => {
        console.log(`Prolog process closed with code ${code}`);
        prologProcess = null;
    });

    // Give the process a moment to start up
    return new Promise((resolve) => {
        setTimeout(() => {
            console.log('✓ Persistent Prolog process started');
            resolve();
        }, 1000);
    });
}

// Function to execute Prolog queries using the persistent process
function queryProlog(query, timeout = 15000) {
    return new Promise((resolve, reject) => {
        if (!prologProcess) {
            reject(new Error('Prolog process not started'));
            return;
        }

        console.log(`Executing Prolog query: ${query}`);
        
        const queryId = Date.now() + Math.random();
        const endMarker = `__END_${queryId}__`;
        
        let output = '';
        let error = '';
        let completed = false;

        const timer = setTimeout(() => {
            if (!completed) {
                completed = true;
                reject(new Error('Prolog query timeout'));
            }
        }, timeout);

        const dataHandler = (data) => {
            const text = data.toString();
            output += text;
            
            // Check if we've received the end marker
            if (text.includes(endMarker)) {
                completed = true;
                clearTimeout(timer);
                
                // Remove the end marker from output
                const result = output.replace(endMarker, '').trim();
                console.log(`Prolog query result: ${result}`);
                
                prologProcess.stdout.removeListener('data', dataHandler);
                prologProcess.stderr.removeListener('data', errorHandler);
                
                resolve(result);
            }
        };

        const errorHandler = (data) => {
            error += data.toString();
        };

        prologProcess.stdout.on('data', dataHandler);
        prologProcess.stderr.on('data', errorHandler);

        // Send the query with an end marker
        try {
            prologProcess.stdin.write(`${query}, write('${endMarker}'), nl.\n`);
        } catch (err) {
            completed = true;
            clearTimeout(timer);
            reject(new Error(`Failed to send query: ${err.message}`));
        }
    });
}

// Initialize game
app.post('/init', async (req, res) => {
    try {
        await queryProlog('init, write("initialized")');
        res.json({ success: true, message: 'Game initialized' });
    } catch (error) {
        console.error('Init error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get current board position
app.get('/position', async (req, res) => {
    try {
        const result = await queryProlog('get_current_board(Position, _Color, _Counter), write_canonical(Position)');
        res.json({ success: true, data: result });
    } catch (error) {
        console.error('Position error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Pick piece and get legal moves
app.post('/pick', async (req, res) => {
    const { pos } = req.body;
    try {
        const result = await queryProlog(`pick_piece(${pos}, LegalMoves), (LegalMoves = [] -> write('[]') ; write_canonical(LegalMoves))`);
        res.json({ success: true, legalMoves: result });
    } catch (error) {
        console.error('Pick error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Place piece
app.post('/place', async (req, res) => {
    const { from, to } = req.body;
    try {
        const result = await queryProlog(`(place_piece(${from}, ${to}) -> write('success') ; write('invalid_move'))`);
        console.log(`Place piece result: "${result}"`); // Debug log
        
        // Check if result contains 'success' (handle extra output like SAFE)
        if (result.includes('success')) {
            res.json({ success: true, message: 'Move made' });
        } else {
            res.json({ success: false, error: 'Invalid move' });
        }
    } catch (error) {
        console.error('Place error:', error);
        res.status(500).json({ success: false, error: error.message }a);
    }
});

// Bot move
app.post('/bot', async (req, res) => {
    try {
        const result = await queryProlog('(bot_move -> write("SUCCESS") ; write("FAILED"))');
        
        if (result.includes('SUCCESS')) {
            // Parse the move and status from the output
            const moveMatch = result.match(/Move: (\d+) to (\d+)/);
            const statusMatch = result.match(/Status: (\w+)/);
            
            if (moveMatch && statusMatch) {
                const from = parseInt(moveMatch[1]);
                const to = parseInt(moveMatch[2]);
                const status = statusMatch[1];
                
                res.json({ 
                    success: true, 
                    move: { from, to },
                    status: status,
                    message: `Bot moved from ${from} to ${to}`,
                    raw_output: result
                });
            } else {
                // Fallback if parsing fails
                res.json({ 
                    success: true, 
                    message: 'Bot move completed but could not parse details',
                    raw_output: result
                });
            }
        } else {
            res.json({ success: false, error: 'Bot move failed', raw_output: result });
        }
    } catch (error) {
        console.error('Bot move error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Game status
app.get('/status', async (req, res) => {
    try {
        const result = await queryProlog('board(Position, Color, Counter), check_game_status(Position, Color, Counter)');
        res.json({ success: true, status: result });
    } catch (error) {
        console.error('Status error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Reset game
app.post('/reset', async (req, res) => {
    try {
        await queryProlog('reset, init, write("game_reset")');
        res.json({ success: true, message: 'Game reset' });
    } catch (error) {
        console.error('Reset error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Undo move
app.post('/undo', async (req, res) => {
    try {
        await queryProlog('(can_undo -> (undo, write("move_undone")) ; write("cannot_undo"))');
        res.json({ success: true, message: 'Move undone' });
    } catch (error) {
        console.error('Undo error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

const PORT = process.env.PORT || 3000;

// Cleanup function
function cleanup() {
    console.log('\nShutting down chess server...');
    if (prologProcess) {
        console.log('Terminating Prolog process...');
        prologProcess.kill();
        prologProcess = null;
    }
    process.exit(0);
}

// Handle shutdown signals
process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);
process.on('exit', cleanup);

// Test SWI-Prolog on startup
console.log('Testing SWI-Prolog installation...');
async function startServer() {
    try {
        const swiPath = findSwiProlog();
        console.log(`✓ SWI-Prolog found at: ${swiPath}`);
        console.log(`✓ Prolog files directory: ${PROLOG_PATH}`);
        
        // Test if chess.pl exists
        const fs = require('fs');
        const chessPath = path.join(PROLOG_PATH, 'chess.pl');
        if (fs.existsSync(chessPath)) {
            console.log(`✓ Chess.pl found at: ${chessPath}`);
        } else {
            console.warn(`⚠ Warning: chess.pl not found at ${chessPath}`);
        }
        
        // Start persistent Prolog process
        await startPrologProcess();
        
        // Start the web server
        app.listen(PORT, () => {
            console.log(`♔ Chess server running on http://localhost:${PORT} ♛`);
            console.log(`📁 Prolog files path: ${PROLOG_PATH}`);
            console.log('\n🚀 Open your browser and navigate to the URL above to play!');
        });
        
    } catch (error) {
        console.error('❌ SWI-Prolog setup error:', error.message);
        console.log('\n📋 To fix this issue:');
        console.log('1. Install SWI-Prolog from: https://www.swi-prolog.org/download/stable');
        console.log('2. Make sure to add SWI-Prolog to your system PATH during installation');
        console.log('3. Or manually add the SWI-Prolog bin directory to your PATH');
        console.log('4. Restart your command prompt/terminal');
        console.log('\nThe server will still start, but Prolog queries will fail until this is fixed.\n');
        
        // Start the web server anyway
        app.listen(PORT, () => {
            console.log(`♔ Chess server running on http://localhost:${PORT} ♛`);
            console.log('⚠ Prolog is not available - chess functionality will not work');
        });
    }
}

// Start the server
startServer();
