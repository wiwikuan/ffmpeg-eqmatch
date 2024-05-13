#!/bin/bash

# ffmpeg-eqmatch.sh
# 這個 script 會自動將目標音訊檔案與參考檔案做 EQ Match。
# 它首先分析兩個音訊檔案的響度值，計算它們在不同頻帶上的差異，
# 然後使用 FFmpeg 的 equalizer 濾鏡對目標音訊檔案進行 EQ 處理，
# 以使其頻率響應盡可能接近參考音訊檔案。

# 用法：ffmpeg-eqmatch.sh <參考檔案> <你想要處理的檔案> [強度（預設 0.3）]

# 檢查是否提供了兩個輸入檔案
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "請提供兩個聲音檔案作為參數，以及一個可選的強度值。"
  echo "用法: $0 <參考檔案> <想要處理的檔案> [強度（預設 0.3）]"
  exit 1
fi

# 將輸入檔案名存儲在變數中
input_file1="$1"
input_file2="$2"

# 如果提供了強度值，則使用它；否則，使用預設值 0.3
if [ $# -eq 3 ]; then
  strength="$3"
else
  strength="0.3"
fi

# 函數：用 ffmpeg 提取響度值
get_loudness_values() {
  local input_file="$1"
  local result=$(ffmpeg -i "$input_file" -filter_complex "
    aformat=channel_layouts=mono,
    acrossover=split=40 80 160 320 480 640 800 1000 1500 2000 3000 4500 6000 10000 15000
    [a][b][c][d][e][f][g][h][i][j][k][l][m][n][o][p],
    [a]ebur128,
    [b]ebur128,
    [c]ebur128,
    [d]ebur128,
    [e]ebur128,
    [f]ebur128,
    [g]ebur128,
    [h]ebur128,
    [i]ebur128,
    [j]ebur128,
    [k]ebur128,
    [l]ebur128,
    [m]ebur128,
    [n]ebur128,
    [o]ebur128,
    [p]ebur128
  " -f null - 2>&1)

  local max_band=16
  local loudness_values=()

  for ((i=2; i<=max_band+1; i++)); do
    local loudness=$(echo "$result" | sed -n "/\[Parsed_ebur128_${i}.*Summary:/,/LRA high:/ p" | grep "I:" | awk '{print $2}')
    loudness_values+=("$loudness")
  done

  echo "${loudness_values[@]}"
}

# 獲取兩個輸入檔案的響度值
echo "正在分析參考檔案的響度值..."
loudness_values1=($(get_loudness_values "$input_file1"))
echo "參考檔案分析完成。"

echo "正在分析目標檔案的響度值..."
loudness_values2=($(get_loudness_values "$input_file2"))
echo "目標檔案分析完成。"

# 計算兩個檔案響度值的差距
loudness_diff=()
for ((i=0; i<${#loudness_values1[@]}; i++)); do
  diff=$(echo "${loudness_values1[$i]} - ${loudness_values2[$i]}" | bc)
  loudness_diff+=("$diff")
done

# 輸出分析結果
echo "參考檔案分析值：${loudness_values1[@]}"
echo "目標檔案分析值：${loudness_values2[@]}"
echo "差距：${loudness_diff[@]}"

# 得到輸入檔案的基本名稱（不包括副檔名）
base_name=$(basename "$input_file2" | cut -d. -f1)

# 構建輸出檔案名
output_file="${base_name}_eqmatch_${strength}.wav"

# 定義 equalizer 參數
eq_params=(
  "equalizer=f=30:t=q:w=1:g=$(echo "${loudness_diff[0]} * $strength" | bc)"
  "equalizer=f=60:t=q:w=1:g=$(echo "${loudness_diff[1]} * $strength" | bc)"
  "equalizer=f=120:t=q:w=1:g=$(echo "${loudness_diff[2]} * $strength" | bc)"
  "equalizer=f=240:t=q:w=1:g=$(echo "${loudness_diff[3]} * $strength" | bc)"
  "equalizer=f=400:t=q:w=1:g=$(echo "${loudness_diff[4]} * $strength" | bc)"
  "equalizer=f=560:t=q:w=1:g=$(echo "${loudness_diff[5]} * $strength" | bc)"
  "equalizer=f=720:t=q:w=1:g=$(echo "${loudness_diff[6]} * $strength" | bc)"
  "equalizer=f=900:t=q:w=1:g=$(echo "${loudness_diff[7]} * $strength" | bc)"
  "equalizer=f=1250:t=q:w=1:g=$(echo "${loudness_diff[8]} * $strength" | bc)"
  "equalizer=f=1750:t=q:w=1:g=$(echo "${loudness_diff[9]} * $strength" | bc)"
  "equalizer=f=2500:t=q:w=1:g=$(echo "${loudness_diff[10]} * $strength" | bc)"
  "equalizer=f=3750:t=q:w=1:g=$(echo "${loudness_diff[11]} * $strength" | bc)"
  "equalizer=f=5250:t=q:w=1:g=$(echo "${loudness_diff[12]} * $strength" | bc)"
  "equalizer=f=8000:t=q:w=1:g=$(echo "${loudness_diff[13]} * $strength" | bc)"
  "equalizer=f=12500:t=q:w=1:g=$(echo "${loudness_diff[14]} * $strength" | bc)"
  "equalizer=f=17500:t=q:w=1:g=$(echo "${loudness_diff[15]} * $strength" | bc)"
)

# 將 equalizer 參數連接成一個字串
eq_filter_string=$(IFS=,; echo "${eq_params[*]}")

# 使用 FFmpeg 對目標檔案進行 EQ 處理
echo "正在對目標檔案進行 EQ 處理..."
ffmpeg -i "$input_file2" -af "$eq_filter_string,alimiter" "$output_file"
echo "EQ 處理完成。輸出檔案：$output_file"
