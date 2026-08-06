#!/bin/bash
# Helper script to package and deploy Ritmo Core Function to Appwrite Cloud

echo "=== اسکریپت آماده‌سازی و بسته بندی فانکشن Appwrite ریتمو ==="

FUNCTION_DIR="backend/functions/core"
OUTPUT_ZIP="ritmo-core-function.zip"

if [ ! -d "$FUNCTION_DIR" ]; then
  echo "خطا: دایرکتوری $FUNCTION_DIR یافت نشد."
  exit 1
fi

echo "۱. در حال ساخت فایل زیپ فانکشن..."
python3 -c "
import zipfile, os
with zipfile.ZipFile('$OUTPUT_ZIP', 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk('$FUNCTION_DIR'):
        for file in files:
            filepath = os.path.join(root, file)
            arcname = os.path.relpath(filepath, '$FUNCTION_DIR')
            z.write(filepath, arcname)
"

echo "✅ فایل $OUTPUT_ZIP با موفقیت در دایرکتوری اصلی ریتمو آماده شد."
echo ""
echo "راهنمای استقرار در Appwrite Console:"
echo "۱. وارد Appwrite Console بخش Functions شوید."
echo "۲. یک فانکشن جدید با نام 'ritmo-core' و زبان 'Node.js 18.0' یا بالاتر بسازید."
echo "۳. فایل $OUTPUT_ZIP را به عنوان Manual Deployment آپلود کنید."
echo "۴. متغیرهای محیطی زیر را در بخش Settings فانکشن قرار دهید:"
echo "   - APPWRITE_API_KEY"
echo "   - SMS_API_TOKEN"
echo "   - SMS_PATTERN_ID"
echo "   - AI_API_KEY"
