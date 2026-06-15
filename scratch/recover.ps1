\ = @()
Get-Content "scratch/chat_screen_1_raw.txt" | ForEach-Object {
    if (\ -match '^\d+:\s(.*)') {
        \ += \[1]
    } elseif (\ -match '^\d+:(.*)') {
        \ += \[1]
    }
}
Get-Content "scratch/chat_screen_2_raw.txt" | ForEach-Object {
    if (\ -match '^([2-4]\d{2}):\s(.*)') {
        if ([int]\[1] -gt 250) {
            \ += \[2]
        }
    } elseif (\ -match '^([2-4]\d{2}):(.*)') {
        if ([int]\[1] -gt 250) {
            \ += \[2]
        }
    }
}
\ | Out-File "scratch/chat_screen_recovered.dart" -Encoding utf8
