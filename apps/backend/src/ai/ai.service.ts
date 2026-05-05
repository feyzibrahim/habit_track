import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private client: GoogleGenAI;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey || apiKey === 'your_gemini_api_key_here') {
      this.logger.warn('GEMINI_API_KEY is not configured correctly in .env');
    }
    this.client = new GoogleGenAI({ apiKey });
  }

  async evaluateFeasibility(
    prompt: string,
    durationDays: number = 90,
    answers?: Record<string, string>,
  ): Promise<any> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated evaluateFeasibility response',
      );
      return {
        feasibility: 'can be done',
        feasibility_reason:
          'This is a simulated AI response indicating feasibility.',
        strategic_analysis:
          'Simulated strategic analysis. Break down the goal into manageable chunks.',
        probability_ratio: 85,
        key_challenges: ['Time management', 'Consistency', 'Focus'],
        graph_data: [
          { label: 'Time Requirement', value: 80 },
          { label: 'Skill Needed', value: 50 },
          { label: 'Consistency', value: 90 },
          { label: 'Energy Cost', value: 70 },
        ],
      };
    }

    let userContext = `The user wants to achieve a major goal (e.g., starting a company, learning a complex skill) within ${durationDays} days.Initial Prompt: ${prompt}`;

    if (answers && Object.keys(answers).length > 0) {
      userContext += `User provided the following additional context:`;
      for (const [q, a] of Object.entries(answers)) {
        userContext += `- Q: ${q}  A: ${a}`;
      }
    }

    const systemPrompt = `You are an elite strategic consultant. 
    ${userContext}
    
    Evaluate the feasibility of the user's goal within the given timeframe.
    
    Options: "not possible", "low", "moderate", "can be done".
    If the goal is absolutely impossible (violates laws of physics or is too extreme for the timeframe), set feasibility to "not possible".
    
    IMPORTANT: You MUST return a JSON object matching this exact structure:
    {
      "feasibility": "low" | "moderate" | "can be done" | "not possible",
      "feasibility_reason": "Executive summary of the feasibility.",
      "strategic_analysis": "3-4 sentences on the high-level strategy required.",
      "probability_ratio": 75,
      "key_challenges": ["Challenge 1", "Challenge 2", "Challenge 3"],
      "graph_data": [
        {"label": "Time Requirement", "value": 80},
        {"label": "Skill Needed", "value": 60},
        {"label": "Consistency", "value": 90},
        {"label": "Financial Cost", "value": 30}
      ]
    }
    
    Rules:
    - Root object MUST have all the above keys.
    - Be realistic, elite, professional.`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-3.1-pro-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        this.logger.log(`Attempting evaluateFeasibility with ${modelName}...`);
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [
            { role: 'user', parts: [{ text: systemPrompt }] },
            { role: 'user', parts: [{ text: prompt }] },
          ],
          config: { responseMimeType: 'application/json' },
        });

        const responseText = result.text;
        if (!responseText) throw new Error('Empty response');

        const parsed = JSON.parse(responseText);
        this.logger.log(
          `AI Success with ${modelName}. Evaluation: ${parsed.feasibility}`,
        );
        return parsed;
      } catch (error) {
        this.logger.warn(`Failed with ${modelName}: ${error.message}`);
        lastError = error;
        continue;
      }
    }

    this.logger.error(
      `AI Evaluation failed for all models: ${lastError.message}`,
    );
    throw new InternalServerErrorException(
      'Failed to evaluate feasibility after model exhaustion',
    );
  }

  async planRoadmap(
    prompt: string,
    durationDays: number = 90,
    answers?: Record<string, string>,
    previousPlan?: any,
    refinementPrompt?: string,
    startDate?: string,
  ): Promise<any> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated planRoadmap response',
      );
      return {
        plan: {
          title: 'Epic Goal Journey',
          description: 'Simulated high-level strategy for achieving the goal.',
          milestones: [
            {
              title: 'Level 1: The Beginning',
              description: 'Establish a strong foundation.',
              target_date: new Date(
                Date.now() + 7 * 24 * 60 * 60 * 1000,
              ).toISOString(),
              action_items: [
                {
                  title: 'Quest: Daily Consistency',
                  description: 'Complete your daily tasks.',
                  type: 'habit',
                  frequency: 'daily',
                  total_target: 7,
                  target_date: new Date(
                    Date.now() + 1 * 24 * 60 * 60 * 1000,
                  ).toISOString(),
                  is_optional: false,
                },
              ],
            },
          ],
        },
      };
    }

    let userContext = `The user wants to achieve a major goal (e.g., starting a company, learning a complex skill) within ${durationDays} days.
    Start Date: ${startDate || new Date().toISOString()}
    Initial Prompt: ${prompt}`;

    if (answers && Object.keys(answers).length > 0) {
      userContext += `User provided the following additional context:`;
      for (const [q, a] of Object.entries(answers)) {
        userContext += `- Q: ${q}  A: ${a}`;
      }
    }

    if (previousPlan && refinementPrompt) {
      userContext += `The user wants to REFINE their previous plan. 
      Previous Plan Title: ${previousPlan.plan?.title || previousPlan.title}
      Refinement Request: ${refinementPrompt}
      Please adjust the milestones based on this new request.`;
    }

    const systemPrompt = `You are an elite agentic planner. 
    ${userContext}
    
    Plan the roadmap.
    Determine the appropriate number of logical phases/milestones based on the complexity of the user's goal and the ${durationDays} days timeframe.
    
    CRITICAL INSTRUCTION: You must assign specific absolute dates ("target_date") using ISO 8601 strings (e.g. "2024-05-01T23:59:59.000Z") for all milestones and action items instead of relative days.
    
    ACTION ITEMS GENERATION LIMIT:
    If the timeframe is > 30 days, define all milestones for the entire timeframe. However, ONLY generate the "action_items" array for milestones that end within the first 30 days. Leave "action_items" as an empty array for later milestones. 
    
    TASK FREQUENCY:
    You MUST generate 1 or more tasks per day. Do not restrict to just one task per day.
    
    GAMIFICATION REQUIREMENT:
    Write the roadmap in an engaging, game-like narrative. Treat the user as a player embarking on a grand quest. Each phase is a "Level" or "Boss Fight", and action items are "Quests" or "Missions" that yield XP. The tone should be motivating and engaging. DO NOT make the title epic sounding; use the exact prompt given by the user for the title.
    
    IMPORTANT: You MUST return a JSON object matching this exact structure:
    {
      "plan": {
        "title": "Exact same prompt given by user",
        "description": "High-level strategy",
        "milestones": [
          {
            "title": "Milestone Title (e.g., Level 1: The Awakening)",
            "description": "What this phase achieves",
            "target_date": "2026-06-01T23:59:59.000Z",
            "action_items": [
              {
                "title": "Action Title (e.g., Quest: First Step)",
                "description": "Specific instruction",
                "type": "task",
                "frequency": null,
                "total_target": 1,
                "target_date": "2026-05-02T23:59:59.000Z",
                "is_optional": false
              },
              {
                "title": "Action Title (e.g., Side Quest: Read Book)",
                "description": "Specific instruction",
                "type": "task",
                "frequency": null,
                "total_target": 1,
                "target_date": "2026-05-02T23:59:59.000Z",
                "is_optional": true
              }
            ]
          }
        ]
      }
    }
    
    Rules:
    - Root object MUST have all the above keys.
    - Be realistic, elite, professional, yet gamified and epic.
    - Ensure EVERY single day for the generated timeframe has at least one required action item mapped to it via 'target_date'.`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-3.1-pro-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        this.logger.log(`Attempting planRoadmap with ${modelName}...`);
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [
            { role: 'user', parts: [{ text: systemPrompt }] },
            { role: 'user', parts: [{ text: prompt }] },
          ],
          config: { responseMimeType: 'application/json' },
        });

        const responseText = result.text;
        if (!responseText) throw new Error('Empty response');

        const parsed = JSON.parse(responseText);
        this.logger.log(`AI Success with ${modelName} for roadmap.`);
        return parsed;
      } catch (error) {
        this.logger.warn(`Failed with ${modelName}: ${error.message}`);
        lastError = error;
        continue;
      }
    }

    this.logger.error(
      `AI Planning failed for all models: ${lastError.message}`,
    );
    throw new InternalServerErrorException(
      'Failed to generate plan after model exhaustion',
    );
  }

  async generateClarifyingQuestions(
    prompt: string,
  ): Promise<{ questions: string[] }> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated generateClarifyingQuestions response',
      );
      return {
        questions: [
          'How much time can you dedicate daily?',
          'What is your current skill level regarding this?',
          'What are your biggest potential roadblocks?',
        ],
      };
    }

    const systemPrompt = `You are an elite strategic coach. The user wants to start a mission: "${prompt}".
    Generate 3 clarifying questions to better understand their situation, constraints, or specific goals.
    
    IMPORTANT: You MUST return a JSON object matching this exact structure:
    {
      "questions": ["Question 1", "Question 2", "Question 3"]
    }`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-3.1-pro-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [{ role: 'user', parts: [{ text: systemPrompt }] }],
          config: {
            responseMimeType: 'application/json',
          },
        });

        const responseText = result.text;
        if (!responseText) throw new Error('Empty response');

        return JSON.parse(responseText);
      } catch (error) {
        this.logger.warn(`Failed with ${modelName}: ${error.message}`);
        lastError = error;
        continue;
      }
    }

    throw new InternalServerErrorException('Failed to generate questions');
  }

  async generateChat(message: string): Promise<{ response: string }> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated generateChat response',
      );
      return {
        response: 'This is a simulated response. Keep up the good work!',
      };
    }

    const systemPrompt = `You are the Mission AI Coach. 
    Help the user with their goals, habits, and strategy. 
    Be concise, encouraging, and highly professional.`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-3.1-pro-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [
            { role: 'user', parts: [{ text: systemPrompt }] },
            { role: 'user', parts: [{ text: message }] },
          ],
        });

        const text = result.text || 'I am focused on your mission.';
        return { response: text };
      } catch (error) {
        this.logger.warn(`Chat failed with ${modelName}: ${error.message}`);
        lastError = error;
        continue;
      }
    }

    throw new InternalServerErrorException(
      'Failed to generate chat after model exhaustion',
    );
  }

  async generateTaskDetails(
    title: string,
    context: string,
  ): Promise<{ description: string; steps: string[] }> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated generateTaskDetails response',
      );
      return {
        description: 'Simulated detailed description for the task.',
        steps: ['Simulated Step 1', 'Simulated Step 2', 'Simulated Step 3'],
      };
    }

    const systemPrompt = `You are an expert coach and strategist. 
    The user is working on a task: "${title}". 
    The context is: "${context}".
    
    Generate a detailed description (2-3 sentences) and a logical list of 3-5 actionable steps to complete this specific task effectively.
    
    Return a JSON object:
    {
      "description": "Specific, helpful description.",
      "steps": ["Step 1...", "Step 2...", "Step 3..."]
    }`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [{ role: 'user', parts: [{ text: systemPrompt }] }],
          config: {
            responseMimeType: 'application/json',
          },
        });

        const responseText = result.text;
        if (!responseText) throw new Error('Empty response');

        return JSON.parse(responseText);
      } catch (error) {
        this.logger.warn(
          `Task details generation failed with ${modelName}: ${error.message}`,
        );
        lastError = error;
        continue;
      }
    }

    throw new InternalServerErrorException('Failed to generate task details');
  }
  async generateTasksForMilestone(
    goalTitle: string,
    milestoneTitle: string,
    milestoneDescription: string,
    goalStartDate: string,
    milestoneTargetDate: string,
  ): Promise<any> {
    if (this.configService.get<string>('MOCK_AI') === 'true') {
      this.logger.log(
        'MOCK_AI is enabled, returning simulated generateTasksForMilestone response',
      );
      return {
        action_items: [
          {
            title: 'Simulated task 1',
            description: 'Task description',
            type: 'task',
            frequency: null,
            total_target: 1,
            target_date: milestoneTargetDate,
            is_optional: false,
          },
        ],
      };
    }

    const systemPrompt = `You are an elite agentic planner.
    The user is pursuing a goal: "${goalTitle}".
    They need daily tasks generated for a specific milestone:
    Milestone Title: ${milestoneTitle}
    Milestone Description: ${milestoneDescription}
    Goal Start Date: ${goalStartDate}
    Milestone Target Date: ${milestoneTargetDate}
    
    CRITICAL INSTRUCTION: You must assign specific absolute dates ("target_date") using ISO 8601 strings (e.g. "2024-05-01T23:59:59.000Z") for all action items. The dates must fall between the previous milestone's target date (or goal start date) and this milestone's target date.
    
    TASK FREQUENCY:
    You MUST generate 1 or more tasks per day. Do not restrict to just one task per day. Include optional tasks if helpful.
    
    Return a JSON object:
    {
      "action_items": [
        {
          "title": "Action Title",
          "description": "Specific instruction",
          "type": "task",
          "frequency": null,
          "total_target": 1,
          "target_date": "2026-05-02T23:59:59.000Z",
          "is_optional": false
        }
      ]
    }`;

    const models = [
      'gemini-3.1-flash-lite-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ];
    let lastError: Error = new Error('Unknown AI error');

    for (const modelName of models) {
      try {
        const result = await this.client.models.generateContent({
          model: modelName,
          contents: [{ role: 'user', parts: [{ text: systemPrompt }] }],
          config: { responseMimeType: 'application/json' },
        });

        const responseText = result.text;
        if (!responseText) throw new Error('Empty response');

        return JSON.parse(responseText);
      } catch (error) {
        this.logger.warn(
          `Milestone tasks generation failed with ${modelName}: ${error.message}`,
        );
        lastError = error;
        continue;
      }
    }

    throw new InternalServerErrorException(
      'Failed to generate tasks for milestone',
    );
  }
}
