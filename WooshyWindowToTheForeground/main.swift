print(
    Workflow.next() == "do"
        ? Workflow.notify(resultFrom: Workflow.do())
        : Workflow.menu()
)
