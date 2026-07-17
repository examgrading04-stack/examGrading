import re
import sys

def modify_sql(filename):
    with open(filename, "r", encoding="utf-8") as f:
        content = f.read()

    # Mapping of table_name -> { old_col: new_col }
    table_map = {
        "admins": {
            "`id`": "`admin_id`",
            "`aname`": "`admin_username`",
            "`apassword`": "`admin_password`"
        },
        "system_logs": {
            "`logid`": "`log_id`",
            "`activity`": "`action`",
            "`datetime`": "`action_time`",
            "`user`": "`user_id`"
        },
        "subjects": {
            "`code`": "`subject_id`",
            "`name`": "`subject_name`",
            "`user_email`": "`user_id`"
        },
        "sections": {
            "`id`": "`section_id`",
            "`sec`": "`section_number`",
            "`subject`": "`subject_id`",
            "`user_email`": "`user_id`"
        },
        "students": {
            "`id`": "`student_id`",
            "`code`": "`student_code`",
            "`name`": "`student_name`",
            "`section`": "`section_id`",
            "`user_email`": "`user_id`"
        }
    }

    # We need to replace these column names in:
    # 1. CREATE TABLE `table` (...)
    # 2. INSERT INTO `table` (...)
    # 3. ALTER TABLE `table` ADD PRIMARY KEY (...) or KEY (...)
    
    # Process line by line or by blocks.
    lines = content.split("\n")
    out_lines = []
    
    current_table = None
    in_create = False
    in_alter = False
    
    for line in lines:
        new_line = line
        
        # Check CREATE TABLE
        m_create = re.match(r"^CREATE TABLE `([^`]+)`", line)
        if m_create:
            current_table = m_create.group(1)
            in_create = True
            
        # Check INSERT INTO
        m_insert = re.match(r"^INSERT INTO `([^`]+)` \((.*?)\)", line)
        if m_insert:
            t = m_insert.group(1)
            if t in table_map:
                cols = m_insert.group(2)
                for old_c, new_c in table_map[t].items():
                    cols = cols.replace(old_c, new_c)
                new_line = f"INSERT INTO `{t}` ({cols})" + line[m_insert.end():]
                
        # Check ALTER TABLE
        m_alter = re.match(r"^ALTER TABLE `([^`]+)`", line)
        if m_alter:
            current_table = m_alter.group(1)
            in_alter = True
            
        # If inside CREATE or ALTER, replace columns if table in map
        if in_create or in_alter:
            if current_table in table_map:
                for old_c, new_c in table_map[current_table].items():
                    new_line = new_line.replace(old_c, new_c)
                    
        # Check end of CREATE or ALTER block
        if in_create and line.startswith(") ENGINE="):
            in_create = False
            current_table = None
            
        # ALTER blocks end with a semicolon or we just reset on empty line
        if in_alter and line.strip() == "":
            in_alter = False
            current_table = None
            
        if in_alter and line.endswith(";"):
            in_alter = False
            current_table = None

        out_lines.append(new_line)
        
    with open(filename, "w", encoding="utf-8") as f:
        f.write("\n".join(out_lines))
        
modify_sql("backend/exam_grading.sql")
print("Done")

