# ffmpeg-eqmatch

超自由、超極簡，只用 `ffmpeg` 就可以 EQ Match！

這個 Bash 腳本使用 FFmpeg，自動將目標音訊檔案與參考音訊檔案進行 EQ Match。它會分析兩個音訊檔案在 16 個頻率帶上的響度值，計算它們的差異，然後使用 FFmpeg 的 equalizer 濾鏡對目標音訊檔案進行 EQ 處理，使其頻率響應接近參考音訊檔案。

## 特點

- 不用買編曲軟體和 Plug-in，只要有參考檔案跟 `ffmpeg` 就好
- 可以調整 EQ Match 的強度
- 只支援 Linux 和 macOS（要改成 Windows 版應該不難，但我沒有 Windows 電腦）

## 用法

```
./ffmpeg-eqmatch.sh <參考檔案> <你想要處理的檔案> [強度（預設 0.3）]
```
