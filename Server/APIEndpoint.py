import os
from fastapi import Depends, FastAPI, HTTPException, Header
from pydantic import BaseModel
from typing import List
from services.Recommendations import generate_recommendations
from services.Scraper import scrape_sem
from services.FirebaseConnection import uploadCourses
import uvicorn

SCRAPE_API_TOKEN_PATH = "SCRAPE_API_TOKEN"

app = FastAPI(title="Study Planner API", version="1.0.0")


class RecommendationRequest(BaseModel):
    totalSemester: int
    currentSemesterRelative: int
    currentSemesterIndex: int
    workload: list[int]
    takenCourses: list[dict]
    likedTags: list[str]
    totalCourses: list[dict]
    plannedCourses: list[list[dict]]

class RecommendationResponse(BaseModel):
    recommendations: list[list[dict]]

class ScrapeRequest(BaseModel):
    is_hs: bool
    year: int

class ScrapeResponse(BaseModel):
    data: List[dict]

class UpdateCoursesRequest(BaseModel):
    whatif_mode: bool = True
    old_semester: bool = False
    is_hs: bool
    year: int
    deprecated_upload: bool = False

class UpdateCoursesResponse(BaseModel):
    changelog: List[dict]

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Study Planner API"}

@app.post("/api/recommendation", response_model=RecommendationResponse)
async def recommendation_request(request: RecommendationRequest):
    recommendations = generate_recommendations(
        total_semesters=request.totalSemester,
        current_semester_relative=request.currentSemesterRelative,
        current_semester_index=request.currentSemesterIndex,
        workload=request.workload,
        taken_courses=request.takenCourses,
        liked_tags=request.likedTags,
        total_courses=request.totalCourses,
        planned_courses=request.plannedCourses
    )
    return RecommendationResponse(recommendations=recommendations)


def verify_token(authorization: str = Header(None)):

    if not os.getenv(SCRAPE_API_TOKEN_PATH):
        raise HTTPException(status_code=500, detail="Server misconfiguration: Missing API token")
    
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header"
        )

    token = authorization.split(" ")[1]
    if token != os.getenv(SCRAPE_API_TOKEN_PATH):
        raise HTTPException(status_code=401, detail="Invalid token")

    return token


@app.post("/api/scrape", response_model=ScrapeResponse)
async def initiate_scraping(
    request: ScrapeRequest,
    token: str = Depends(verify_token)
):
    data = scrape_sem(isHs=request.is_hs, year=request.year)
    return ScrapeResponse(data=data)


@app.post("/api/update-courses", response_model=UpdateCoursesResponse)
async def update_courses(
    request: UpdateCoursesRequest,
    token: str = Depends(verify_token)
):
    data = scrape_sem(isHs=request.is_hs, year=request.year)
    changelog = uploadCourses(data, isHs=request.is_hs, year=request.year, whatif_mode=request.whatif_mode, deprecated_upload=request.deprecated_upload)
    return UpdateCoursesResponse(changelog=changelog)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)