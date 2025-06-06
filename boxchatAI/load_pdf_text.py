from pdfminer.high_level import extract_text
from docx import Document
import os

# Tạo các thư mục nếu chưa tồn tại
os.makedirs("data", exist_ok=True)
os.makedirs("md", exist_ok=True)

def export_pdf_to_md(pdf_path, out_md):
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(f"Không tìm thấy file: {pdf_path}")
    print(f"Đang xử lý {pdf_path}...")
    text = extract_text(pdf_path)
    text = "# " + os.path.basename(pdf_path) + "\n\n" + text
    with open(out_md, "w", encoding="utf-8") as f:
        f.write(text)

def export_docx_to_md(docx_path, out_md):
    if not os.path.exists(docx_path):
        raise FileNotFoundError(f"Không tìm thấy file: {docx_path}")
    print(f"Đang xử lý {docx_path}...")
    doc = Document(docx_path)
    text = "# " + os.path.basename(docx_path) + "\n\n"
    text += "\n\n".join(p.text.strip() for p in doc.paragraphs if p.text.strip())
    with open(out_md, "w", encoding="utf-8") as f:
        f.write(text)

# Xuất file sang Markdown
try:
    export_pdf_to_md("D:/LapTrinhDiDong/question_and_answer_edu/question_and_answer_study/boxchatAI/data/CTDT_AI.pdf", "md/ai.md")
    export_pdf_to_md("D:/LapTrinhDiDong/question_and_answer_edu/question_and_answer_study/boxchatAI/data/CTDT_KTPM.pdf", "md/ktpm.md")
    export_docx_to_md("D:/LapTrinhDiDong/question_and_answer_edu/question_and_answer_study/boxchatAI/data/CTDT_CNTT.docx", "md/cntt.md")
    print("Đã xuất tất cả dữ liệu CTDT sang Markdown thành công.")
except Exception as e:
    print(f"Lỗi khi xuất file: {e}")