import firebase_admin

from services.Const import COURSE_CATEGORIES
from firebase_admin import credentials, firestore

FIREBASE_CREDENTIALS_PATH = "./files/ethcreditplanner-firebase-adminsdk-nhc0u-19295d0072.json"

cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
app = firebase_admin.initialize_app(cred)
db = firestore.client()


def getSemesterId(isHs: bool, year: int) -> int:
    return (year - 2019) * 2 + (1 if isHs else 0)


def generateSemesterIfNeeded(isHs: bool, year: int):
    
    semesterRef = db.collection("semester").document(str(getSemesterId(isHs, year)))
    semester = {
        "isHs": isHs,
        "year": year,
        "courses": []
    }
    semesterRef.set(semester, merge=True)


def stringToCategoryID(category: str) -> int:
    return next((cat["id"] for cat in COURSE_CATEGORIES if cat["name"] == category), -1)
        

def diff_objects(old: dict, new: dict) -> list[str]:

    changes = []
    for key in set(old.keys()) | set(new.keys()):
        old_val = old.get(key) if key in old.keys() else None
        new_val = new.get(key) if key in new.keys() else None

        if not isinstance(old_val, type(new_val)) or old_val != new_val or (isinstance(old_val, list) and sorted(old_val) != sorted(new_val)):
            changes.append({
                "field": key,
                "old": old_val,
                "new": new_val
            })
    return changes

def uploadCourses(course_data: list[dict], isHs: bool, year: int, whatif_mode: bool, deprecated_upload: bool):

    COURSE_COLLECTION = "courses" if deprecated_upload else "cs-bsc-courses"
    changelog = []

    semester_id = getSemesterId(isHs, year)
    if not whatif_mode:
        generateSemesterIfNeeded(isHs, year)

    semesterRef = db.collection("semester").document(str(semester_id))
    semesterDoc = semesterRef.get().to_dict()

    categoryRefs = [db.collection("categories").document(str(i)) for i in range(len(COURSE_CATEGORIES))]
    categoryDocs = [ref.get().to_dict() for ref in categoryRefs]
    
    for doc in course_data:

        id_without_category = doc["id"]

        change = {
            "id": id_without_category,
            "added_to_category": False
        }

        if not deprecated_upload:
            doc["id"] =  doc["id"] + "&&" + str(stringToCategoryID(doc["category"]))
        
        category = stringToCategoryID(doc["category"])
        firedoc_ref = db.collection(COURSE_COLLECTION).document(doc["id"])
        firedoc = firedoc_ref.get()
        newDoc = {
            "id": doc["id"],
            "name": doc["name"],
            "credits": doc["ects"],
            "category": category,
            "tags": doc["tags"],
            "semester": [semester_id],
            "vvz": doc["vvz-link"]
        }
        
        if firedoc.exists:
            change["new"] = False

            for tag in firedoc.to_dict()["tags"]:
                if not(tag in newDoc["tags"]):
                    newDoc["tags"].append(tag)
            
            for semester in firedoc.to_dict()["semester"]:
                if not(semester in newDoc["semester"]):
                    newDoc["semester"].append(semester)

            change["changes"] = diff_objects(firedoc.to_dict(), newDoc)
        else:
            change["new"] = True
            change["new_value"] = newDoc 
        
        newDoc["tags"].sort()
        newDoc["semester"].sort()
        
        if not whatif_mode:
            firedoc_ref.set(newDoc)

        if not(id_without_category in categoryDocs[category]["courses"]):
            categoryDocs[category]["courses"].append(id_without_category)
            change["added_to_category"] = True
        
        changelog.append(change)

    if not whatif_mode:
        semesterRef.set(semesterDoc)
        for i in range(len(COURSE_CATEGORIES)):
            categoryRefs[i].set(categoryDocs[i])

    return changelog