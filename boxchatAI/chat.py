import os
from llama_index.core import (
    VectorStoreIndex,
    Document,
    StorageContext,
    load_index_from_storage,
    Settings
)
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.ollama import OllamaEmbedding
from datetime import datetime

FOLDER_MAP = {
    "Trí tuệ nhân tạo": ("storage_ai", "md/ai.md"),
    "Công nghệ thông tin": ("storage_cntt", "md/cntt.md"),
    "Kỹ thuật phần mềm": ("storage_ktpm", "md/ktpm.md"),
}

INDEX_CACHE = {}

def khoi_tao_index(nganh: str):
    if nganh in INDEX_CACHE:
        print(f"{datetime.now()} - Sử dụng index từ cache cho ngành: {nganh}")
        return INDEX_CACHE[nganh]

    print(f"{datetime.now()} - Bắt đầu khởi tạo index cho ngành: {nganh}")
    Settings.llm = Ollama(model="llama3", request_timeout=240, temperature=0)
    Settings.embed_model = OllamaEmbedding(model_name="llama3")

    folder, file_path = FOLDER_MAP.get(nganh, (None, None))
    if not folder or not file_path:
        raise ValueError(f"Không hỗ trợ ngành: {nganh}")

    if os.path.exists(folder):
        print(f"{datetime.now()} - Tải index từ storage: {folder}")
        sc = StorageContext.from_defaults(persist_dir=folder)
        index = load_index_from_storage(sc)
    else:
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Không tìm thấy file Markdown: {file_path}")

        print(f"{datetime.now()} - Đọc file Markdown: {file_path}")
        with open(file_path, encoding="utf-8") as f:
            full_text = f.read()

        doc = Document(text=full_text)
        print(f"{datetime.now()} - Tạo index từ documents")
        index = VectorStoreIndex.from_documents([doc])
        index.storage_context.persist(folder)

    INDEX_CACHE[nganh] = index
    print(f"{datetime.now()} - Hoàn tất khởi tạo index")
    return index

def loc_theo_tu_khoa(cau_hoi: str, raw_texts: list[str]) -> str:
    tu_khoa = [
        "tín chỉ", "học phần", "tốt nghiệp", "thời gian", "năm", "điều kiện",
        "ngành", "mục tiêu", "chuẩn đầu ra", "nghề nghiệp", "bằng cấp", "thực tập",
        "đào tạo"  # Thêm từ khóa "đào tạo"
    ]
    cau_hoi_lower = cau_hoi.lower()
    if any(k in cau_hoi_lower for k in tu_khoa):
        ket_qua = [t for t in raw_texts if any(k in t.lower() for k in tu_khoa)]
        return "\n".join(ket_qua) if ket_qua else "\n".join(raw_texts)
    return "\n".join(raw_texts)

def hoi_ai(index, cau_hoi: str, nganh: str) -> str:
    print(f"{datetime.now()} - Xử lý câu hỏi: {cau_hoi}, ngành: {nganh}")
    try:
        doc_ids = list(index.docstore.docs.keys())
        print("Danh sách doc_id:", doc_ids)

        if not doc_ids:
            raise ValueError("Không có document nào trong index.")

        doc_id = doc_ids[0]  # Lấy document đầu tiên
        doc = index.storage_context.docstore.get_document(doc_id)
        if doc is None:
            raise ValueError("Không tìm thấy document trong index")

        noi_dung = doc.text[:1500]  # Tăng giới hạn lên 3000 ký tự
        print(f"Nội dung document (đoạn đầu): {noi_dung[:300]}...")
    except Exception as e:
        print(f"Lỗi khi lấy document: {e}")
        raise

    prompt = f"""
Chỉ sử dụng thông tin trong phần TÀI LIỆU dưới đây để trả lời.

**YÊU CẦU NGHIÊM NGẶT**:
- **CHỈ TRẢ LỜI BẰNG TIẾNG VIỆT**
- **Dịch toàn bộ các thuật ngữ hoặc cụm từ tiếng Anh sang tiếng Việt nếu có**
- **Không được sử dụng bất kỳ từ tiếng Anh nào trong câu trả lời**
- **Trình bày ngắn gọn, rõ ràng, đúng nội dung tài liệu**
- **Không được tự bịa thêm nội dung**

Nếu không có thông tin trong tài liệu, hãy trả lời chính xác:
"Tôi không biết."

Cuối câu trả lời phải có dòng sau:
"Trích từ Chương trình đào tạo ngành {nganh}."

-------- TÀI LIỆU --------
{noi_dung}
---------------------------

Câu hỏi: {cau_hoi}
Trả lời:
"""
    print(f"{datetime.now()} - Gửi yêu cầu đến Ollama")
    llm = Ollama(model="llama3", request_timeout=120, temperature=0)
    try:
        response = llm.complete(prompt).text.strip()
        print(f"{datetime.now()} - Nhận phản hồi từ Ollama: {response}")
        return response
    except Exception as e:
        print(f"Lỗi khi gọi Ollama: {e}")
        raise

def main():
    print("=== Chat với AI HSU (gõ 'exit' để thoát) ===")
    try:
        nganh = input("Bạn học ngành gì (Trí tuệ nhân tạo / Công nghệ thông tin / Kỹ thuật phần mềm)? ").strip()
        index = khoi_tao_index(nganh)
    except Exception as e:
        print(f"[LỖI KHỞI TẠO]: {e}")
        return

    while True:
        try:
            user_input = input("\nBạn: ").strip()
            if user_input.lower() == "exit":
                print("Tạm biệt!")
                break
            if not user_input:
                continue

            tra_loi = hoi_ai(index, user_input, nganh)
            if tra_loi:
                print(f"AI: {tra_loi}")
        except KeyboardInterrupt:
            print("\nTạm biệt!")
            break
        except Exception as err:
            print(f"[LỖI]: {err}")

if __name__ == "__main__":
    main()