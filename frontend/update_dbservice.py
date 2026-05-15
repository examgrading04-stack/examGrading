import os
import re

frontend_dir = r"d:\ExamGrading\frontend"

new_db_service = """const dbService = {
            async getDocs(collectionName) {
                if (currentUser && currentUser.email) {
                    const snapshot = await db.collection('users').doc(currentUser.email).collection(collectionName).get();
                    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
                }
                return [];
            },
            async addDoc(collectionName, data) {
                if (currentUser && currentUser.email) {
                    const docRef = await db.collection('users').doc(currentUser.email).collection(collectionName).add(data);
                    return docRef.id;
                }
                throw new Error("Authentication required to save data.");
            },
            async setDocWithId(collectionName, customId, data) {
                if (currentUser && currentUser.email) {
                    await db.collection('users').doc(currentUser.email).collection(collectionName).doc(customId).set(data);
                    return customId;
                }
                throw new Error("Authentication required to save data.");
            },
            async updateDoc(collectionName, id, data) {
                if (currentUser && currentUser.email) {
                    await db.collection('users').doc(currentUser.email).collection(collectionName).doc(id).update(data);
                } else {
                    throw new Error("Authentication required to update data.");
                }
            },
            async deleteDoc(collectionName, id) {
                if (currentUser && currentUser.email) {
                    await db.collection('users').doc(currentUser.email).collection(collectionName).doc(id).delete();
                } else {
                    throw new Error("Authentication required to delete data.");
                }
            }
        };"""

pattern = re.compile(r"const\s+dbService\s*=\s*\{.*?\n\s*\};\n", re.DOTALL)

for filename in os.listdir(frontend_dir):
    if filename.endswith(".html"):
        filepath = os.path.join(frontend_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Replace dbService
        if pattern.search(content):
            # Try to match the indentation of the original `const dbService = {`
            match = re.search(r"([ \t]*)const\s+dbService\s*=", content)
            indent = match.group(1) if match else "        "
            
            # Indent the new code correctly
            indented_db_service = "\n".join([(indent + line.lstrip() if line.strip() else line) for line in new_db_service.split("\n")])
            indented_db_service = indented_db_service.replace(indent + "const dbService", "const dbService", 1)
            indented_db_service = match.group(1) + indented_db_service + "\n"

            new_content = pattern.sub(indented_db_service, content)
            
            # Also replace any explicit currentUser.uid outside dbService
            # such as in legacy fallback code
            new_content = new_content.replace("currentUser.uid", "currentUser.email")

            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated {filename}")
        else:
            print(f"No dbService found in {filename}")
