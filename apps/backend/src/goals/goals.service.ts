import {
  Injectable,
  NotFoundException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { User } from '../users/user.entity';
import { ActionItem } from './action-item.entity';
import { Goal } from './goal.entity';
import { Milestone } from './milestone.entity';
import { TaskStep } from './task-step.entity';
import { XpService } from '../xp/xp.service';

@Injectable()
export class GoalsService {
  private readonly logger = new Logger(GoalsService.name);
  constructor(
    @InjectRepository(Goal)
    private goalRepository: Repository<Goal>,
    @InjectRepository(Milestone)
    private milestoneRepository: Repository<Milestone>,
    @InjectRepository(ActionItem)
    private actionItemRepository: Repository<ActionItem>,
    @InjectRepository(TaskStep)
    private taskStepRepository: Repository<TaskStep>,
    private aiService: AiService,
    private xpService: XpService,
  ) {}

  async getClarifyingQuestions(prompt: string) {
    this.logger.log(`Generating clarifying questions for prompt: ${prompt}`);
    return this.aiService.generateClarifyingQuestions(prompt);
  }

  async evaluateGoal(
    userId: string,
    prompt: string,
    durationDays: number = 90,
    answers?: Record<string, string>,
    startDate?: string,
  ) {
    this.logger.log(
      `Evaluating feasibility for user ${userId} (${durationDays} days): ${prompt.substring(0, 50)}...`,
    );
    const aiResponse = await this.aiService.evaluateFeasibility(prompt, durationDays, answers);

    if (aiResponse.feasibility === 'not possible') {
      return {
        feasibility: aiResponse.feasibility,
        reason: aiResponse.feasibility_reason,
        probability_ratio: aiResponse.probability_ratio || 0,
        plan: null,
      };
    }

    return aiResponse;
  }

  async generateRoadmap(
    userId: string,
    prompt: string,
    durationDays: number = 90,
    answers?: Record<string, string>,
    previousPlan?: any,
    refinementPrompt?: string,
    startDate?: string,
  ) {
    this.logger.log(
      `Generating roadmap for user ${userId} (${durationDays} days): ${prompt.substring(0, 50)}...`,
    );
    return this.aiService.planRoadmap(prompt, durationDays, answers, previousPlan, refinementPrompt, startDate);
  }

  async createGoal(
    user: User,
    prompt: string,
    aiPlan: any,
    durationDays: number = 90,
    category: string = 'other',
    feasibility: string = 'moderate',
    startDate?: string,
  ) {
    if (!aiPlan || !aiPlan.plan) {
      this.logger.error(
        `Invalid Plan Data received: ${JSON.stringify(aiPlan)}`,
      );
      throw new BadRequestException(
        'The AI was unable to generate a valid roadmap for this mission.',
      );
    }

    this.logger.log(
      `Creating goal for user ${user.id}: ${aiPlan.plan.title} (${durationDays} days)`,
    );
    const actualStartDate = startDate ? new Date(startDate) : new Date();

    const goal = this.goalRepository.create({
      user,
      title: aiPlan.plan.title,
      description: aiPlan.plan.description,
      prompt,
      category,
      feasibility: feasibility,
      feasibilityReason: aiPlan.feasibility_reason || null,
      strategicAnalysis: aiPlan.strategic_analysis || null,
      probabilityRatio: aiPlan.probability_ratio || 0,
      keyChallenges: aiPlan.key_challenges || [],
      graphData: aiPlan.graph_data || [],
      durationDays: durationDays,
      startDate: actualStartDate,
      targetDate: new Date(actualStartDate.getTime() + durationDays * 24 * 60 * 60 * 1000),
      status: 'active',
    });

    const savedGoal = await this.goalRepository.save(goal);
    this.logger.log(
      `Goal saved (ID: ${savedGoal.id}). Architecting ${aiPlan.plan.milestones.length} milestones...`,
    );

    let milestoneOrder = 1;

    for (const m of aiPlan.plan.milestones) {
      const milestoneTargetDate = m.target_date ? new Date(m.target_date) : new Date(actualStartDate.getTime() + (m.days_from_start || 7) * 24 * 60 * 60 * 1000);

      const milestone = this.milestoneRepository.create({
        goal: savedGoal,
        title: m.title,
        description: m.description,
        order: milestoneOrder++,
        targetDate: milestoneTargetDate,
      });

      const savedMilestone = await this.milestoneRepository.save(milestone);
      this.logger.log(
        `Milestone Phase ${savedMilestone.order} created. Syncing action items...`,
      );

      if (m.action_items && Array.isArray(m.action_items)) {
        for (const a of m.action_items) {
          const actionTargetDate = a.target_date ? new Date(a.target_date) : milestoneTargetDate;
          actionTargetDate.setHours(23, 59, 59, 999);

          const actionItem = this.actionItemRepository.create({
            milestone: savedMilestone,
            title: a.title,
            description: a.description,
            type: a.type || 'task',
            frequency: a.frequency || null,
            totalTarget: a.total_target || 1,
            isOptional: a.is_optional || false,
            targetDate: actionTargetDate,
          });
          await this.actionItemRepository.save(actionItem);
        }
      }
    }

    return this.getGoalDetails(savedGoal.id);
  }

  async getGoalDetails(goalId: string) {
    return this.goalRepository.findOne({
      where: { id: goalId },
      relations: [
        'milestones',
        'milestones.actionItems',
        'milestones.actionItems.steps',
      ],
      order: {
        milestones: {
          order: 'ASC',
        },
      },
    });
  }

  async getUserGoals(userId: string) {
    return this.goalRepository.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
    });
  }

  async updateActionItem(actionItemId: string, isCompleted: boolean) {
    const actionItem = await this.actionItemRepository.findOne({
      where: { id: actionItemId },
      relations: ['milestone', 'milestone.goal', 'milestone.goal.user'],
    });
    if (!actionItem) {
      this.logger.warn(`Action item not found: ${actionItemId}`);
      throw new NotFoundException('Action item not found');
    }

    this.logger.log(
      `Updating action item ${actionItemId}: isCompleted=${isCompleted}`,
    );
    actionItem.isCompleted = isCompleted;
    if (isCompleted && actionItem.type === 'habit') {
      actionItem.completedCount += 1;
      await this.xpService.addXpEvent(actionItem.milestone.goal.user, actionItem.title, `Habit Maintained x${actionItem.completedCount}`, 2);
    } else if (isCompleted && actionItem.type === 'task') {
      await this.xpService.addXpEvent(actionItem.milestone.goal.user, actionItem.title, 'Action Item Completed', 10);
    }
    return this.actionItemRepository.save(actionItem);
  }

  async generateAndSaveSteps(actionItemId: string) {
    const actionItem = await this.actionItemRepository.findOne({
      where: { id: actionItemId },
      relations: ['milestone', 'milestone.goal', 'steps'],
    });

    if (!actionItem) throw new NotFoundException('Action item not found');

    // If steps already exist and have content, don't regenerate (optional, but requested to reuse)
    if (actionItem.steps && actionItem.steps.length > 0) {
      return actionItem;
    }

    const context = `Goal: ${actionItem.milestone.goal.title}. Milestone: ${actionItem.milestone.title}. Task Type: ${actionItem.type}. Frequency: ${actionItem.frequency}`;
    const aiDetails = await this.aiService.generateTaskDetails(
      actionItem.title,
      context,
    );

    // Update description if it was empty
    if (!actionItem.description || actionItem.description === '') {
      actionItem.description = aiDetails.description;
      await this.actionItemRepository.save(actionItem);
    }

    // Save steps
    const steps = aiDetails.steps.map((text, index) => {
      const step = new TaskStep();
      step.text = text;
      step.order = index;
      step.actionItem = actionItem;
      return step;
    });

    await this.taskStepRepository.save(steps);

    return this.actionItemRepository.findOne({
      where: { id: actionItemId },
      relations: ['steps'],
    });
  }

  async toggleStep(stepId: string, isCompleted: boolean) {
    const step = await this.taskStepRepository.findOne({
      where: { id: stepId },
      relations: ['actionItem', 'actionItem.milestone', 'actionItem.milestone.goal', 'actionItem.milestone.goal.user'],
    });
    if (!step) throw new NotFoundException('Step not found');

    step.isCompleted = isCompleted;
    step.completedAt = isCompleted ? new Date() : undefined;
    
    if (isCompleted) {
      await this.xpService.addXpEvent(step.actionItem.milestone.goal.user, step.text, 'Action Step Completed', 5);
    }
    
    return this.taskStepRepository.save(step);
  }

  async generateTasksForMilestone(milestoneId: string) {
    const milestone = await this.milestoneRepository.findOne({
      where: { id: milestoneId },
      relations: ['goal', 'actionItems'],
    });

    if (!milestone) throw new NotFoundException('Milestone not found');

    if (milestone.actionItems && milestone.actionItems.length > 0) {
      this.logger.warn(`Milestone ${milestoneId} already has tasks, skipping generation.`);
      return milestone;
    }

    this.logger.log(`Generating tasks on-demand for Milestone ${milestoneId}`);
    
    // In order to give context to AI, we tell it the start/end dates
    const startDate = milestone.goal.startDate.toISOString();
    const milestoneTarget = milestone.targetDate.toISOString();

    const result = await this.aiService.generateTasksForMilestone(
      milestone.goal.title,
      milestone.title,
      milestone.description,
      startDate,
      milestoneTarget
    );

    if (result && result.action_items) {
      for (const a of result.action_items) {
        const actionTargetDate = a.target_date ? new Date(a.target_date) : new Date(milestoneTarget);
        actionTargetDate.setHours(23, 59, 59, 999);

        const actionItem = this.actionItemRepository.create({
          milestone: milestone,
          title: a.title,
          description: a.description,
          type: a.type || 'task',
          frequency: a.frequency || null,
          totalTarget: a.total_target || 1,
          isOptional: a.is_optional || false,
          targetDate: actionTargetDate,
        });
        await this.actionItemRepository.save(actionItem);
      }
    }

    return this.milestoneRepository.findOne({
      where: { id: milestoneId },
      relations: ['actionItems', 'actionItems.steps'],
    });
  }
}
