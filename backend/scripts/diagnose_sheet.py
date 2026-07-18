try:
    from backend.app.services.diagnostics import main
except ModuleNotFoundError:
    from app.services.diagnostics import main


if __name__ == "__main__":
    main()
