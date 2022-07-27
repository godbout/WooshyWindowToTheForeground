import WooshyWindowToTheForegroundCore


print(
    Workflow.next() == "do"
        ? Workflow.do()
        : Workflow.menu()
)
