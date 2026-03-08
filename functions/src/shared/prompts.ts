/**
 * LLM Prompt Templates — exact templates from Architecture Doc Section 6
 * Both prompts instruct the model to return ONLY valid JSON.
 */

interface TaskForRecalib {
  taskId: string;
  title: string;
  description: string;
  priority: string;
  status: string;
  parentId: string | null;
  level: number;
}

/**
 * DECOMPOSE_PROMPT — used in processVoice.ts
 * Returns JSON: { projectTitle, projectDescription, epics[] with nested subtasks[] }
 */
export const DECOMPOSE_PROMPT = (transcript: string): string => `
You are a task decomposition engine for a product manager.
Given a voice transcript of their thoughts, extract a structured project.

Return ONLY valid JSON matching this exact schema:
{
  "projectTitle": string,
  "projectDescription": string,
  "epics": [
    {
      "title": string,
      "description": string,
      "priority": "low" | "medium" | "high",
      "subtasks": [
        {
          "title": string,
          "description": string,
          "priority": "low" | "medium" | "high"
        }
      ]
    }
  ]
}

Rules:
- Generate 2-5 epics maximum
- Generate 2-4 subtasks per epic
- Be specific and actionable — not vague
- Do not invent work not mentioned in the transcript
- If the transcript is unclear, generate fewer, broader tasks

Transcript: ${transcript}
`;

/**
 * RECALIBRATE_PROMPT — used in recalibrateProject.ts
 * Takes incomplete tasks + KB text, returns changes[] and newTasks[]
 */
export const RECALIBRATE_PROMPT = (
  tasks: TaskForRecalib[],
  kbText: string
): string => `
You are a task recalibration engine.
Given a list of incomplete tasks and a new knowledge base document,
suggest improvements ONLY where the document provides relevant new context.

Return ONLY valid JSON:
{
  "changes": [
    {
      "taskId": string,
      "field": "title" | "description" | "priority",
      "newValue": string,
      "reason": string
    }
  ],
  "newTasks": [
    {
      "parentId": string | null,
      "level": 1 | 2,
      "title": string,
      "description": string,
      "priority": "low" | "medium" | "high",
      "reason": string
    }
  ]
}

Rules:
- NEVER modify tasks unless the document provides clear justification
- NEVER suggest changes to completed or locked tasks
- Keep changes minimal and targeted — do not rewrite everything
- reason must reference the document specifically

Incomplete Tasks: ${JSON.stringify(tasks)}

Knowledge Base Document: ${kbText}
`;

/**
 * GENERATE_SUBTASKS_PROMPT — used in generateSubtasks.ts
 * Takes an epic and generates subtasks using Gemini Flash
 */
export const GENERATE_SUBTASKS_PROMPT = (
  epicTitle: string,
  epicDescription: string
): string => `
You are a subtask generation engine for a product manager.
Given an epic task, generate specific, actionable subtasks.

Return ONLY valid JSON:
{
  "subtasks": [
    {
      "title": string,
      "description": string,
      "priority": "low" | "medium" | "high"
    }
  ]
}

Rules:
- Generate 2-4 subtasks
- Each subtask must be specific and actionable
- Do not repeat the epic itself as a subtask
- Subtasks should break down the epic into concrete steps

Epic Title: ${epicTitle}
Epic Description: ${epicDescription}
`;
