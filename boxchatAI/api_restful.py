from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict
from chat import khoi_tao_index, hoi_ai
import asyncio
from datetime import datetime

app = FastAPI(
    title="RESTful API hỏi đáp AI HSU",
    description="API hỗ trợ chọn ngành học và trả lời theo đúng ngành",
    version="1.0.1"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép tất cả (hoặc cụ thể cho ứng dụng Flutter)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware để xử lý timeout
async def timeout_middleware(request, call_next):
    try:
        return await asyncio.wait_for(call_next(request), timeout=120)  # Tăng timeout lên 120 giây
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Server xử lý quá lâu (timeout)")

app.middleware("http")(timeout_middleware)

# Kiểu dữ liệu nhận từ client
class Question(BaseModel):
    question: str
    major: str

fake_db: Dict[int, Dict[str, str]] = {}
current_id = 0

def detect_major(question: str, original_major: str) -> str:
    """Tự động chọn ngành dựa trên câu hỏi."""
    question_lower = question.lower()
    if "trí tuệ nhân tạo" in question_lower or "ai" in question_lower:
        return "Trí tuệ nhân tạo"
    elif "kỹ thuật phần mềm" in question_lower or "ktpm" in question_lower:
        return "Kỹ thuật phần mềm"
    elif "công nghệ thông tin" in question_lower or "cntt" in question_lower:
        return "Công nghệ thông tin"
    return original_major  # Giữ nguyên major nếu không phát hiện từ khóa

@app.post("/ask")
async def post_question(q: Question):
    global current_id
    # Tự động chọn ngành dựa trên câu hỏi
    detected_major = detect_major(q.question, q.major)
    print(f"{datetime.now()} - Nhận yêu cầu: question={q.question}, major={q.major}, detected_major={detected_major}")
    
    try:
        index = khoi_tao_index(detected_major)
    except Exception as e:
        print(f"{datetime.now()} - Lỗi khởi tạo index: {e}")
        raise HTTPException(status_code=400, detail=str(e))

    answer = hoi_ai(index, q.question, detected_major)
    print(f"{datetime.now()} - Trả lời: {answer}")
    fake_db[current_id] = {"question": q.question, "answer": answer, "major": detected_major}
    response = {"id": current_id, "question": q.question, "answer": answer}
    current_id += 1
    return response

@app.get("/ask/{qid}")
def get_question(qid: int):
    if qid not in fake_db:
        raise HTTPException(status_code=404, detail="Không tìm thấy câu hỏi")
    return fake_db[qid]

@app.delete("/ask/{qid}")
def delete_question(qid: int):
    if qid not in fake_db:
        raise HTTPException(status_code=404, detail="Không tìm thấy để xoá")
    del fake_db[qid]
    return {"message": f"Đã xoá câu hỏi ID {qid}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api_restful:app", host="0.0.0.0", port=8000, reload=True)