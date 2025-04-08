#!/bin/bash

# 檢查是否安裝了ImageMagick
if ! command -v identify &> /dev/null || ! command -v convert &> /dev/null; then
    echo "錯誤: 此腳本需要ImageMagick。請使用以下命令安裝:"
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo "  CentOS/RHEL: sudo yum install imagemagick"
    exit 1
fi

# Claude圖片上傳限制
MAX_FILE_SIZE_MB=30
MAX_DIMENSION=8000
MIN_RECOMMENDED_DIMENSION=1000

# 顯示使用說明
usage() {
    echo "使用方法: $0 <圖片路徑> [分割數量]"
    echo "  <圖片路徑>: 要處理的圖片文件路徑"
    echo "  [分割數量]: 可選，指定要分割的份數。如不指定，將自動根據尺寸決定"
    exit 1
}

# 檢查參數
if [ $# -lt 1 ]; then
    usage
fi

IMAGE_PATH="$1"
SPLIT_COUNT="${2:-0}"  # 如果未指定分割數量，預設為0（自動）

# 檢查文件是否存在
if [ ! -f "$IMAGE_PATH" ]; then
    echo "錯誤: 找不到圖片 '$IMAGE_PATH'"
    exit 1
fi

# 獲取圖片資訊
IMAGE_INFO=$(identify -format "%w %h %b %d %f" "$IMAGE_PATH")
WIDTH=$(echo $IMAGE_INFO | cut -d' ' -f1)
HEIGHT=$(echo $IMAGE_INFO | cut -d' ' -f2)
FILE_SIZE_BYTES=$(echo $IMAGE_INFO | cut -d' ' -f3)
DEPTH=$(echo $IMAGE_INFO | cut -d' ' -f4)
FILENAME=$(echo $IMAGE_INFO | cut -d' ' -f5-)

# 轉換文件大小為MB
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE_BYTES / 1048576" | bc)

# 獲取文件名和擴展名
BASENAME=$(basename "$IMAGE_PATH")
FILENAME="${BASENAME%.*}"
EXTENSION="${BASENAME##*.}"
DIR_PATH=$(dirname "$IMAGE_PATH")

echo "圖片資訊:"
echo "  文件名: $BASENAME"
echo "  尺寸: ${WIDTH}x${HEIGHT} 像素"
echo "  文件大小: ${FILE_SIZE_MB}MB"
echo "  色彩深度: $DEPTH"

# 判斷是否需要分割
NEED_SPLIT=false
SPLIT_REASON=""

if (( $(echo "$FILE_SIZE_MB > $MAX_FILE_SIZE_MB" | bc -l) )); then
    NEED_SPLIT=true
    SPLIT_REASON="文件大小超過${MAX_FILE_SIZE_MB}MB限制"
fi

if [ $WIDTH -gt $MAX_DIMENSION ] || [ $HEIGHT -gt $MAX_DIMENSION ]; then
    NEED_SPLIT=true
    SPLIT_REASON="圖片尺寸超過${MAX_DIMENSION}x${MAX_DIMENSION}像素限制"
fi

# 如果用戶指定了分割數量，則強制分割
if [ $SPLIT_COUNT -gt 1 ]; then
    NEED_SPLIT=true
    SPLIT_REASON="用戶指定分割為${SPLIT_COUNT}份"
fi

# 如果不需要分割
if [ "$NEED_SPLIT" = false ]; then
    echo "此圖片不需要分割，符合Claude上傳要求。"
    exit 0
fi

echo "需要分割圖片: $SPLIT_REASON"

# 確定分割方向和分割數量
if [ $SPLIT_COUNT -le 1 ]; then
    # 自動確定分割數量
    if [ $WIDTH -gt $HEIGHT ]; then
        # 寬度較大，水平分割
        SPLIT_DIRECTION="horizontal"
        if [ $WIDTH -gt $MAX_DIMENSION ]; then
            SPLIT_COUNT=$(( ($WIDTH + $MAX_DIMENSION - 1) / $MAX_DIMENSION ))
        else
            # 根據文件大小來決定分割數量
            SPLIT_COUNT=$(( (${FILE_SIZE_MB/.*} + $MAX_FILE_SIZE_MB - 1) / $MAX_FILE_SIZE_MB ))
        fi
    else
        # 高度較大或相等，垂直分割
        SPLIT_DIRECTION="vertical"
        if [ $HEIGHT -gt $MAX_DIMENSION ]; then
            SPLIT_COUNT=$(( ($HEIGHT + $MAX_DIMENSION - 1) / $MAX_DIMENSION ))
        else
            # 根據文件大小來決定分割數量
            SPLIT_COUNT=$(( (${FILE_SIZE_MB/.*} + $MAX_FILE_SIZE_MB - 1) / $MAX_FILE_SIZE_MB ))
        fi
    fi
    
    # 確保至少分成1份
    if [ $SPLIT_COUNT -lt 1 ]; then
        SPLIT_COUNT=1
    fi
else
    # 用戶指定了分割數量，根據圖片尺寸決定分割方向
    if [ $WIDTH -gt $HEIGHT ]; then
        SPLIT_DIRECTION="horizontal"
    else
        SPLIT_DIRECTION="vertical"
    fi
fi

echo "將圖片分割為 $SPLIT_COUNT 份，分割方向: $SPLIT_DIRECTION"

# 執行分割
SPLIT_FILES=()

if [ "$SPLIT_DIRECTION" = "horizontal" ]; then
    # 每份的寬度
    SLICE_WIDTH=$(( $WIDTH / $SPLIT_COUNT ))
    
    for (( i=0; i<$SPLIT_COUNT; i++ )); do
        START_X=$(( $i * $SLICE_WIDTH ))
        # 最後一份可能需要調整寬度以涵蓋所有剩餘像素
        if [ $i -eq $(( $SPLIT_COUNT - 1 )) ]; then
            CURRENT_WIDTH=$(( $WIDTH - $START_X ))
        else
            CURRENT_WIDTH=$SLICE_WIDTH
        fi
        
        OUTPUT_FILE="${DIR_PATH}/${FILENAME}_part$(( $i + 1 )).${EXTENSION}"
        convert "$IMAGE_PATH" -crop ${CURRENT_WIDTH}x${HEIGHT}+${START_X}+0 "$OUTPUT_FILE"
        
        SPLIT_FILES+=("$OUTPUT_FILE")
        echo "已生成分割檔案: $OUTPUT_FILE"
    done
else
    # 垂直分割
    SLICE_HEIGHT=$(( $HEIGHT / $SPLIT_COUNT ))
    
    for (( i=0; i<$SPLIT_COUNT; i++ )); do
        START_Y=$(( $i * $SLICE_HEIGHT ))
        # 最後一份可能需要調整高度以涵蓋所有剩餘像素
        if [ $i -eq $(( $SPLIT_COUNT - 1 )) ]; then
            CURRENT_HEIGHT=$(( $HEIGHT - $START_Y ))
        else
            CURRENT_HEIGHT=$SLICE_HEIGHT
        fi
        
        OUTPUT_FILE="${DIR_PATH}/${FILENAME}_part$(( $i + 1 )).${EXTENSION}"
        convert "$IMAGE_PATH" -crop ${WIDTH}x${CURRENT_HEIGHT}+0+${START_Y} "$OUTPUT_FILE"
        
        SPLIT_FILES+=("$OUTPUT_FILE")
        echo "已生成分割檔案: $OUTPUT_FILE"
    done
fi

# 生成Claude提示文本
# 直接顯示提示文本，不生成文件
echo ""
echo "提示內容:"
echo "以下是一張被分割的圖片，共${SPLIT_COUNT}個部分。請在分析時將它們視為同一張圖片。"
if [ "$SPLIT_DIRECTION" = "horizontal" ]; then
    echo "分割方向: 水平方向（寬度方向被切分）"
else
    echo "分割方向: 垂直方向（高度方向被切分）"
fi
echo "原始圖片尺寸: ${WIDTH}x${HEIGHT} 像素"
echo "請按照順序將這些圖片在${SPLIT_DIRECTION}方向上拼接起來進行分析。"
echo ""

echo "圖片處理完成！共分割為${#SPLIT_FILES[@]}個部分。"