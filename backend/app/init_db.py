from app.db.session import engine, Base
from app.models import *  # Import all models to register them with Base
from app.create_admin import create_admin

def init_db():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully.")
    
    print("Creating admin user...")
    create_admin()

if __name__ == "__main__":
    init_db()
