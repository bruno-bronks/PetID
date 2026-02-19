from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash

def create_admin():
    db = SessionLocal()
    try:
        email = "admin@petid.com"
        password = "admin123"
        
        user = db.query(User).filter(User.email == email).first()
        if user:
            print(f"User {email} already exists.")
            # Optional: Update password
            # user.password_hash = get_password_hash(password)
            # db.commit()
        else:
            print(f"Creating user {email}...")
            user = User(
                email=email,
                password_hash=get_password_hash(password),
                full_name="Admin",
                is_active=True
            )
            db.add(user)
            db.commit()
            print(f"User {email} created successfully with password '{password}'")
            
    except Exception as e:
        print(f"Error creating admin: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
