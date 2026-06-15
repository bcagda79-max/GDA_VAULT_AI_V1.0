const fs = require('fs');
let content = fs.readFileSync('scratch/chat_screen_recovered.dart', 'utf8');

// Complete the missing parts
content += 
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: canSend ? AppTokens.lightBrandPrimary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: canSend 
                      ? Colors.white 
                      : (isDark ? const Color(0xFF555555) : AppTokens.lightBorderMedium),
                ),
                onPressed: canSend ? _sendMessage : null,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
;

fs.writeFileSync('lib/features/ai_chat/chat_screen.dart', content);
