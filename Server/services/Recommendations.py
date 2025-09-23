import random
from services.Const import COURSE_CATEGORIES
from ortools.sat.python import cp_model

def calculate_course_score(course: dict, liked_tags: list[str]) -> int:
    return random.randint(1, 100)

def generate_potential_courses_with_preference(taken_courses: list[dict], liked_tags: list[str], total_courses: list[dict], current_semester_index: int, current_semester_is_hs: bool) -> list[dict]:
    """
    Returns a list of courses that have not yet been taken, each with an additional 'score' containing the user's preference for that course and hs based on if the course is in HS or FS.
    Further this method filters out courses that have not been offered in the current and previous semester
    """
    taken_ids = [course['id'] for course in taken_courses]
    potential_courses = [course for course in total_courses if course["id"] not in taken_ids and (current_semester_index in course["semester"] or current_semester_index - 1 in course["semester"])]
    for course in potential_courses:
        course['score'] = calculate_course_score(course, liked_tags)
        course['hs'] = True if current_semester_index in course["semester"] and current_semester_is_hs or current_semester_index not in course["semester"] and not current_semester_is_hs else False
    return potential_courses


def group_potential_courses_by_category(potential_courses: list[dict]) -> dict:
    """
    Returns a dictionary where the keys are category IDs (as strings) and the values are lists of courses in that category that have not yet been taken.
    """
    grouped_by_category = {}
    for i in range(len(COURSE_CATEGORIES)):
        grouped_by_category[str(i)] = sorted([course for course in potential_courses if course["category"] == i], key=lambda x: x['score'], reverse=True)
    return grouped_by_category

def generate_initial_credits_per_category(taken_courses: list[dict], planned_courses: list[dict]) -> dict:
    """
    Returns a dictionary where the keys are category IDs (as strings) and the values are the total credits taken/planned in that category.
    """
    initial_credits = {str(i): 0 for i in range(len(COURSE_CATEGORIES))}
    for course in taken_courses + planned_courses:
        category_id = course["category"]
        initial_credits[str(category_id)] += course["credits"]
    return initial_credits

def allocate_next_course_at_least_workload(current_allocation: list, course_to_allocate: dict, min_semester: int, current_semester_is_hs: bool):
    """
    Allocates the course to the semester with the least workload that is at least min_semester and matches the course's hs/fs requirement.
    """
    min_semester_is_hs = min_semester % 2 == (1 if current_semester_is_hs else 0)
    start_semester = min_semester if min_semester_is_hs == course_to_allocate['hs'] else min_semester + 1
    credit_distribution = get_ects_distribution_of_allocation([current_allocation[i] for i in range(start_semester, len(current_allocation), 2)])
    min_index = credit_distribution.index(min(credit_distribution))
    current_allocation[start_semester + min_index * 2].append(course_to_allocate)


def allocate_next_course_as_early_as_possible(current_allocation: list[list[dict]], course_to_allocate: dict, current_semester_is_hs: bool):
    """
    Allocates the course to the earliest semester that matches the course's hs/fs requirement.
    """
    allocation_index = 0 if current_semester_is_hs and course_to_allocate['hs'] or not current_semester_is_hs and not course_to_allocate['hs'] else 1
    current_allocation[allocation_index].append(course_to_allocate)

def get_ects_distribution_of_allocation(allocation: list):
    """
    Returns the ECTS distribution of the given allocation.
    """
    return [sum(course['credits'] for course in semester) for semester in allocation]

def greedily_allocate_to_category_min(current_allocation: list[list[dict]], credits_per_category: dict, potential_courses_by_category: dict, current_semester_is_hs: bool):
    """
    Greedily allocates courses to the current allocation until the minimum required credits for each category are met.
    """
    last_basis_semester = -1
    # Fill base year examinations first
    while credits_per_category['0'] < COURSE_CATEGORIES[0]['min_ects']:
        next_course = potential_courses_by_category['0'].pop(0)
        allocate_next_course_as_early_as_possible(current_allocation, next_course, current_semester_is_hs)
        credits_per_category['0'] += next_course['credits']
    
    if any(course["category"] == 0 for course in current_allocation[0]):
        last_basis_semester = 0
    if any(course["category"] == 0 for course in current_allocation[1]):
        last_basis_semester = 1

    # Allocate thesis in last semester
    if credits_per_category['7'] < COURSE_CATEGORIES[7]['min_ects']:
        next_course = potential_courses_by_category['7'].pop(0)
        current_allocation[-1].append(next_course)
        credits_per_category['7'] += next_course['credits']

    # Allocate core and basic courses in round-robin fashion
    num_core_to_allocate = max((COURSE_CATEGORIES[2]['min_ects'] - credits_per_category['2'])/8, 0)
    core_to_allocate = [potential_courses_by_category['2'].pop(0) for _ in range(int(num_core_to_allocate))]
    core_has_fs = any(course["category"] == 2 and not course["hs"] for course in (course for semester in current_allocation for course in semester)) or any (not course["hs"] for course in core_to_allocate)

    if not core_has_fs:
        next_fs_course = next((course for course in potential_courses_by_category['2'] if not course['hs']), None)
        core_to_allocate.append(next_fs_course)
        potential_courses_by_category['2'].remove(next_fs_course)
        potential_courses_by_category['2'].append(core_to_allocate.pop(-2))
    
    while credits_per_category['1'] < COURSE_CATEGORIES[1]['min_ects']:
        allocate_next_course_at_least_workload(current_allocation, potential_courses_by_category['1'].pop(0), last_basis_semester + 1, current_semester_is_hs)
        credits_per_category['1'] += next_course['credits']
        if credits_per_category['2'] < COURSE_CATEGORIES[2]['min_ects'] and core_to_allocate:
            next_course = core_to_allocate.pop(0)
            allocate_next_course_at_least_workload(current_allocation, next_course, last_basis_semester + 1, current_semester_is_hs)
            credits_per_category['2'] += next_course['credits']
    
    # Fill core category
    while credits_per_category['2'] < COURSE_CATEGORIES[2]['min_ects'] and core_to_allocate:
        next_course = core_to_allocate.pop(0)
        allocate_next_course_at_least_workload(current_allocation, next_course, last_basis_semester + 1, current_semester_is_hs)
        credits_per_category['2'] += next_course['credits']
    
    # Allocate minor
    while credits_per_category['3'] < COURSE_CATEGORIES[3]['min_ects']:
        next_course = next((course for course in potential_courses_by_category['3'] if course["credits"] + credits_per_category['3'] <= 10), None)
        allocate_next_course_at_least_workload(current_allocation, next_course, last_basis_semester + 1, current_semester_is_hs)
        credits_per_category['3'] += next_course['credits']

    # Allocate seminar
    next_course = potential_courses_by_category['6'].pop(0)
    allocate_next_course_at_least_workload(current_allocation, next_course, last_basis_semester + 1, current_semester_is_hs)
    credits_per_category['6'] += next_course['credits']

    # Allocate science in perspective
    two_courses = [next((course for course in potential_courses_by_category['5'] if course["credits"] == 3), None)]
    two_courses.append(next((course for course in potential_courses_by_category['5'] if course["credits"] == 3 and course["hs"] != two_courses[0]["hs"]), None))

    three_courses = [next((course for course in potential_courses_by_category['5'] if course["credits"] == 2), None)]
    three_courses.append(next((course for course in potential_courses_by_category['5'] if course["credits"] == 2 and course not in three_courses), None))
    if three_courses[0]["hs"] == three_courses[1]["hs"]:
        three_courses.append(next((course for course in potential_courses_by_category['5'] if course["credits"] == 2 and course["hs"] != three_courses[0]["hs"]), None))
    else:
        three_courses.append(next((course for course in potential_courses_by_category['5'] if course["credits"] == 2 and course not in three_courses), None))

    average_index_two_courses = sum(potential_courses_by_category['5'].index(course) for course in two_courses if course) / len([course for course in two_courses if course])
    average_index_three_courses = sum(potential_courses_by_category['5'].index(course) for course in three_courses if course) / len([course for course in three_courses if course])
    if average_index_two_courses < average_index_three_courses or credits_per_category['5'] != 0 and credits_per_category['5'] % 3 == 0:
        while credits_per_category['5'] < COURSE_CATEGORIES[5]['min_ects']:
            course = two_courses.pop(0)
            allocate_next_course_at_least_workload(current_allocation, course, last_basis_semester + 1, current_semester_is_hs)
            credits_per_category['5'] += course['credits']
            potential_courses_by_category['5'].remove(course)
    else:
        while credits_per_category['5'] < COURSE_CATEGORIES[5]['min_ects']:
            course = three_courses.pop(0)
            allocate_next_course_at_least_workload(current_allocation, course, last_basis_semester + 1, current_semester_is_hs)
            credits_per_category['5'] += course['credits']
            potential_courses_by_category['5'].remove(course)

def fill_free_credits(current_allocation: list[list[dict]], free_credits_total: int, free_credits_minor: int, potential_courses_by_category: dict, current_semester_is_hs: bool):
    model = cp_model.CpModel()
    
    decision_vars_core = [model.NewBoolVar(f"core_{i}") for i in range(len(potential_courses_by_category['2']))]
    decision_vars_minor = [model.NewBoolVar(f"minor_{i}") for i in range(len(potential_courses_by_category['3']))]
    decision_vars_electives = [model.NewBoolVar(f"elective_{i}") for i in range(len(potential_courses_by_category['4']))]

    model.Add(sum(decision_vars_core[i] * potential_courses_by_category['2'][i]['credits'] for i in range(len(potential_courses_by_category['2']))) +
              sum(decision_vars_minor[i] * potential_courses_by_category['3'][i]['credits'] for i in range(len(potential_courses_by_category['3']))) +
              sum(decision_vars_electives[i] * potential_courses_by_category['4'][i]['credits'] for i in range(len(potential_courses_by_category['4']))) == free_credits_total)
    
    model.Add(sum(decision_vars_minor[i] * potential_courses_by_category['3'][i]['credits'] for i in range(len(potential_courses_by_category['3']))) <= free_credits_minor)

    model.Maximize(sum(decision_vars_core[i] * potential_courses_by_category['2'][i]['score'] for i in range(len(potential_courses_by_category['2']))) +
                   sum(decision_vars_minor[i] * potential_courses_by_category['3'][i]['score'] for i in range(len(potential_courses_by_category['3']))) +
                   sum(decision_vars_electives[i] * potential_courses_by_category['4'][i]['score'] for i in range(len(potential_courses_by_category['4']))))

    solver = cp_model.CpSolver()
    status = solver.Solve(model)
    if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
        for i in range(len(potential_courses_by_category['2'])):
            if solver.Value(decision_vars_core[i]) == 1:
                allocate_next_course_at_least_workload(current_allocation, potential_courses_by_category['2'][i], 0, current_semester_is_hs)
        for i in range(len(potential_courses_by_category['3'])):
            if solver.Value(decision_vars_minor[i]) == 1:
                allocate_next_course_at_least_workload(current_allocation, potential_courses_by_category['3'][i], 0, current_semester_is_hs)
        for i in range(len(potential_courses_by_category['4'])):
            if solver.Value(decision_vars_electives[i]) == 1:
                allocate_next_course_at_least_workload(current_allocation, potential_courses_by_category['4'][i], 0, current_semester_is_hs)
    else:
        raise Exception()

def generate_recommendations(total_semesters: int, current_semester_relative: int, current_semester_index: int, workload: list[int], taken_courses: list[dict], liked_tags: list[str], total_courses: list[dict], planned_courses: list[list[dict]]):
    
    current_semester_is_hs = current_semester_index % 2 == 1
    potential_courses_by_category = group_potential_courses_by_category(generate_potential_courses_with_preference(taken_courses, liked_tags, total_courses, current_semester_index, current_semester_is_hs))
    credits_per_category = generate_initial_credits_per_category(taken_courses, [course for semester in planned_courses for course in semester])
    
    greedily_allocate_to_category_min(planned_courses, credits_per_category, potential_courses_by_category, current_semester_is_hs)

    total_credits = sum([course['credits'] for semester in planned_courses for course in semester])
    total_credits += sum([course['credits'] for course in taken_courses])

    free_credits_total = 180 - total_credits
    free_credits_minor = 10 - credits_per_category['3']

    fill_free_credits(planned_courses, free_credits_total, free_credits_minor, potential_courses_by_category, current_semester_is_hs)

    # Remove score and hs fields before returning
    for semester in planned_courses:
        for course in semester:
            course.pop('score', None)
            course.pop('hs', None)

    return planned_courses



