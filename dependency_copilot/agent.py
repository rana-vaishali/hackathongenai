import os
from dotenv import load_dotenv
from google.adk.agents import LlmAgent
from google.adk.tools.agent_tool import AgentTool
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

load_dotenv()

MODEL = os.getenv("MODEL", "gemini-2.5-flash")
TOOLBOX_URL = os.getenv("TOOLBOX_URL")

snapshot_agent = LlmAgent(
    name="snapshot_agent",
    model=MODEL,
    description="Reads project snapshot, current tasks, and blocker notes.",
    instruction="""
You are the Project Snapshot Agent.
Use the MCP tools to retrieve project task state and blocker notes.
Return a short project snapshot.
""",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=f"{TOOLBOX_URL}/mcp"
            ),
            tool_filter=["get_project_snapshot", "get_blocker_notes"],
        )
    ],
)

dependency_agent = LlmAgent(
    name="dependency_agent",
    model=MODEL,
    description="Analyzes dependency risk and blocked chains.",
    instruction="""
You are the Dependency Risk Agent.
Use the MCP tools to identify blocked tasks and dependency chains.
Return the highest-risk dependency chain and explain why it matters.
""",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=f"{TOOLBOX_URL}/mcp"
            ),
            tool_filter=["get_blocked_tasks", "get_dependency_chain"],
        )
    ],
)

followup_agent = LlmAgent(
    name="followup_agent",
    model=MODEL,
    description="Creates follow-up tasks and saves summaries.",
    instruction="""
You are the Follow-up Action Agent.
Use the MCP tools to create follow-up tasks and save an action summary.

When the user asks for follow-up tasks, infer the critical blockers from the project snapshot, blocked tasks, blocker notes, and dependency chain.
Do not ask the user to list the blockers again if the project context already contains enough information.
Create practical follow-up tasks for the most critical blocking items.
""",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=f"{TOOLBOX_URL}/mcp"
            ),
            tool_filter=["create_followup_task", "save_action_summary"],
        )
    ],
)

checkpoint_agent = LlmAgent(
    name="checkpoint_agent",
    model=MODEL,
    description="Schedules a checkpoint event.",
   instruction="""
You are the Checkpoint Scheduling Agent.
Use the MCP tool to create a checkpoint event when the user asks for it.

If the user says "tomorrow at 10 AM", interpret it directly and create the checkpoint.
Do not ask for confirmation unless the date or time is completely missing.
""",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=f"{TOOLBOX_URL}/mcp"
            ),
            tool_filter=["create_checkpoint_event"],
        )
    ],
)

root_agent = LlmAgent(
    name="dependency_copilot",
    model=MODEL,
    description="Root agent that coordinates project dependency analysis.",
    instruction="""
You are Dependency Copilot.

You coordinate these sub-agents:
- snapshot_agent
- dependency_agent
- followup_agent
- checkpoint_agent

Your job is to answer questions like:
- what is blocked in a project
- what is highest risk
- what follow-up tasks should be created
- whether a checkpoint should be scheduled

Always return:
1. project snapshot
2. blocked items / dependency risk
3. actions created
4. next recommendation
""",
    tools=[
        AgentTool(snapshot_agent),
        AgentTool(dependency_agent),
        AgentTool(followup_agent),
        AgentTool(checkpoint_agent),
    ],
)