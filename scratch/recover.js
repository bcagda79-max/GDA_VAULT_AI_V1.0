const fs = require('fs');
const lines1 = fs.readFileSync('scratch/chat_screen_1_raw.txt', 'utf8').split('\n');
const lines2 = fs.readFileSync('scratch/chat_screen_2_raw.txt', 'utf8').split('\n');

const out = [];

const processLines = (lines, startLine) => {
    let reading = false;
    for (const line of lines) {
        if (line.includes('The following code has been modified')) {
            reading = true;
            continue;
        }
        if (line.includes('The above content does NOT show the entire file contents')) {
            reading = false;
            break;
        }
        if (reading) {
            const match = line.match(/^\d+:\s?(.*)/);
            if (match) {
                out.push(match[1]);
            }
        }
    }
};

processLines(lines1);
// For lines2, skip the first 250 lines to avoid duplication if any
let reading2 = false;
for (const line of lines2) {
    if (line.includes('The following code has been modified')) {
        reading2 = true;
        continue;
    }
    if (line.includes('The above content does NOT show the entire file contents')) {
        reading2 = false;
        break;
    }
    if (reading2) {
        const match = line.match(/^(\d+):\s?(.*)/);
        if (match) {
            if (parseInt(match[1], 10) > 250) {
                out.push(match[2]);
            }
        }
    }
}

fs.writeFileSync('scratch/chat_screen_recovered.dart', out.join('\n'));
