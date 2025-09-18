import requests
from bs4 import BeautifulSoup

DE_ALL_INF_BSC = "https://www.vorlesungen.ethz.ch/Vorlesungsverzeichnis/sucheLehrangebot.view?deptId=5&studiengangTyp=BSC&ansicht=2&lang=de"
GESS_A_URL = ""
GESS_B_URL = ""
SPRACHKURS_URL = ""

ALL_INF_BSC = "https://www.vorlesungen.ethz.ch/Vorlesungsverzeichnis/sucheLehrangebot.view?deptId=5&studiengangTyp=BSC&ansicht=2&lang=en"

def scrape_url(URL:str, sem:str,search_gess:bool=False):
    if search_gess:
        #update the global urls if found:
        global GESS_A_URL
        global GESS_B_URL
        global SPRACHKURS_URL

    # Send a GET request to the website
    response = requests.get(URL)

    #print(URL)

    # Check if the request was successful
    if response.status_code == 200:
        # Parse the HTML content of the page
        soup = BeautifulSoup(response.content, 'html.parser')

        # get the table rows
        rows = soup.find_all('tr')

        if(len(rows) == 0):
            return -1

        #define level switching: 
        last_level = -1
        program = ""
        cat = ""
        tags = []
        entries = []

        # process row data:
        last_course = 1111111111111111111
        for row in rows:
            level_indicator = len(row.find_all(class_='levelIndicator'))
            txt = row.get_text().strip()

            if(level_indicator == 0):
                if(row.find(class_='td-level')):
                    program = txt
                    last_course = 1111111111111111111

                else:
                    if ('-' in txt and 'credits' in txt):
                        if ('Does not take place this semester' in txt):
                            last_course = 1111111111111111111
                            continue
                        
                        try: 
                            nbr = row.find('b').get_text()
                            info = row.find('a')
                            mstr = info.get_text()
                            kp_field = row.find('td', string=lambda x: x and 'credits' in x)
                            kp = int(kp_field.get_text().split("\xa0")[0]) if kp_field else 0
                            link = "https://www.vvz.ethz.ch" + info.get('href')

                            entry = {
                                'program': program,
                                'category': cat,
                                'tags': tags.copy(),
                                'semester': sem,
                                'id': nbr,
                                'name': mstr,
                                'ects': kp,
                                'vvz-link': link
                            }
                            entries.append(entry)
                            # Update last_course to point to the last added entry
                            last_course = len(entries) - 1
                        except Exception as error:
                            print("==========ERROR=========")
                            print(error)
                           # raise AttributeError(f"No course data found on this url: {URL}")
                    else: 
                        if txt.startswith('Abstract') and last_course < len(entries):
                            #add information to courses which take place
                            entries[last_course]['Abstract'] = txt[8:]

                        if txt.startswith('Learning objective') and last_course < len(entries):
                            #add information to courses which take place
                            entries[last_course]['Learning objective'] = txt[18:]

                        if txt.startswith('Content') and last_course < len(entries):
                            #add information to courses which take place
                            entries[last_course]['Content'] = txt[7:]


                        if search_gess:
                            if ("Science in Perspective" in cat) and row.find('a'):
                                #the link found in the current row
                                href = "https://www.vorlesungen.ethz.ch"+row.find('a').get('href')

                                if "Type A" in row.get_text():
                                    GESS_A_URL = href
                                if "Type B" in row.get_text():
                                    GESS_B_URL = href
                                if "Language Courses" in row.get_text():
                                    SPRACHKURS_URL = href

                last_level = 0

            else:
                # perform category switch logic here:
                if(level_indicator == 1):
                    cat = row.find('a').get_text().strip()
                    tags = []
                    last_level = 1

                if(level_indicator == 2):
                    tags = [row.get_text().strip()]

        return entries

    else:
        print(f"Failed to retrieve the webpage. Status code: {response.status_code}")
        return -1


def scrape_gess(sem:str):
    targets = {GESS_A_URL,GESS_B_URL,SPRACHKURS_URL}
    
    for ln in targets:
        if ln == "" or not ln.endswith("&seite=1"):
            raise ValueError(f"no valid link found for {ln}")


    # scrape type A course data:
    gess_data_A = []
    index=1
    curr = scrape_url(f"{GESS_A_URL[:-1]}{index}",sem)
    while not curr == -1:
        gess_data_A.extend(curr)
        index += 1
        curr = scrape_url(f"{GESS_A_URL[:-1]}{index}",sem)

    # Overwrite all categories in the gess_data_A dictionary list
    for entry in gess_data_A:
        entry['program'] = 'Computer Science Bachelor'
        entry['category'] = 'Science in Perspective'
        entry['tags'].append('Type A')
    

    #scrape type B course data:
    gess_data_B = []
    index=1
    curr = scrape_url(f"{GESS_B_URL[:-1]}{index}",sem)
    while not curr == -1:
        gess_data_B.extend(curr)
        index += 1
        curr = scrape_url(f"{GESS_B_URL[:-1]}{index}",sem)

    # Overwrite all categories in the gess_data_B dictionary list
    for entry in gess_data_B:
        entry['program'] = 'Computer Science Bachelor'
        entry['category'] = 'Science in Perspective'
        entry['tags'].append('Type B')
    

    # scrape Sprachkurse
    gess_SP = []
    index=1
    curr = scrape_url(f"{SPRACHKURS_URL[:-1]}{index}",sem)
    while not curr == -1:
        gess_SP.extend(curr)
        index += 1
        curr = scrape_url(f"{SPRACHKURS_URL[:-1]}{index}",sem)

    # Overwrite all categories in the gessSP dictionary list
    for entry in gess_SP:
        entry['program'] = 'Computer Science Bachelor'
        entry['category'] = 'Science in Perspective'
        entry['tags'].append('Language Courses')

    
    #debug information:
    print(f"found {len(gess_data_A)} Type A courses, {len(gess_data_B)} Type B courses and {len(gess_SP)} Sprachkurse")

    return gess_data_A + gess_data_B + gess_SP

def scrape_sem(isHs, year):
    FS = not(isHs)
    HS = isHs

    global GESS_A_URL
    global GESS_B_URL
    global SPRACHKURS_URL
    fs_year = year
    hs_year = year

    GESS_A_URL = ""
    GESS_B_URL = ""
    SPRACHKURS_URL = ""

    if(FS):
        FS_KEYS = f"&semkez={fs_year}S&seite="
        
        try:
            #try fetching this year
            data = scrape_url(f"{ALL_INF_BSC}{FS_KEYS}1",'FS',True)
        except AttributeError:
            #default back last year
            fs_year -= 1
            FS_KEYS = f"&semkez={fs_year}S&seite="
            data = scrape_url(f"{ALL_INF_BSC}{FS_KEYS}1",'FS',True)
        
        print(f"scraping from: {ALL_INF_BSC}{FS_KEYS}")
        
        #scrape remaining pages:
        index=2
        curr = scrape_url(f"{ALL_INF_BSC}{FS_KEYS}{index}",'FS',True)
        while not curr == -1:
            data.extend(curr)
            index += 1
            curr = scrape_url(f"{ALL_INF_BSC}{FS_KEYS}{index}",'FS',True)
        
        #debug information
        print(f"Inf courses: {len(data)} courses for FS{fs_year} from {index-1} pages")
        print("scraping for gess courses:")

        data += scrape_gess('FS')

        data = [item for item in data if item.get('program') == 'Computer Science Bachelor']

        print(f"Done. Total courses found for FS{fs_year}: {len(data)}")

    
    GESS_A_URL = ""
    GESS_B_URL = ""
    SPRACHKURS_URL = ""

    if(HS):
        HS_KEYS = f"&semkez={hs_year}W&seite="
        
        try:
            #try fetching this year
            data = scrape_url(f"{ALL_INF_BSC}{HS_KEYS}1",'HS',True)
        except AttributeError:
            #default back last year
            hs_year -= 1
            HS_KEYS = f"&semkez={hs_year}W&seite="
            data = scrape_url(f"{ALL_INF_BSC}{HS_KEYS}1",'HS',True)
        
        print(f"scraping from: {ALL_INF_BSC}{HS_KEYS}")
        
        #scrape remaining pages:
        index=2
        curr = scrape_url(f"{ALL_INF_BSC}{HS_KEYS}{index}",'HS',True)
        while not curr == -1:
            data.extend(curr)
            index += 1
            curr = scrape_url(f"{ALL_INF_BSC}{HS_KEYS}{index}",'HS',True)
        
        #debug information
        print(f"Inf courses: {len(data)} courses for HS{hs_year} from {index-1} pages")
        print("scraping for gess courses:")

        data += scrape_gess('HS')

        data = [item for item in data if item.get('program') == 'Computer Science Bachelor']

        print(f"Done. Total courses found for HS{hs_year}: {len(data)}")
    
    return data