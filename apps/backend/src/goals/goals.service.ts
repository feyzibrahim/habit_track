import {
  Injectable,
  NotFoundException,
  Logger,
  BadRequestException,
  OnApplicationBootstrap,
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
export class GoalsService implements OnApplicationBootstrap {
  private readonly logger = new Logger(GoalsService.name);
  
  onApplicationBootstrap() {
    this.logger.log('GoalsService initialized, starting periodic side quests checker...');
    // Run immediately
    this.generateDailySideQuestsForAllGoals().catch(err => {
      this.logger.error('Failed to generate daily side quests:', err);
    });

    // Run every 1 hour (3600000 ms)
    setInterval(() => {
      this.generateDailySideQuestsForAllGoals().catch(err => {
        this.logger.error('Failed periodic side quests check:', err);
      });
    }, 3600000);
  }

  async generateDailySideQuestsForAllGoals() {
    this.logger.log('Checking all active goals for today\'s side quests...');
    const activeGoals = await this.goalRepository.find({
      where: { status: 'active' },
      relations: ['milestones', 'milestones.actionItems'],
    });

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    for (const goal of activeGoals) {
      let currentMilestone = goal.milestones.find(m => !m.isCompleted);
      if (!currentMilestone && goal.milestones.length > 0) {
        currentMilestone = goal.milestones[goal.milestones.length - 1];
      }

      if (!currentMilestone) continue;

      const todaysSideQuests = currentMilestone.actionItems.filter(item => {
        if (!item.isOptional || !item.targetDate) return false;
        const target = new Date(item.targetDate);
        return target.getFullYear() === today.getFullYear() &&
               target.getMonth() === today.getMonth() &&
               target.getDate() === today.getDate();
      });

      if (todaysSideQuests.length === 0) {
        this.logger.log(`Generating dynamic daily Side Quest for Goal "${goal.title}"...`);
        
        let sideQuestTitle = 'Side Quest: Stay Hydrated';
        let sideQuestDesc = 'Drink 3L of water today to keep your operational focus and energy at absolute maximum.';
        
        const cat = (goal.category || 'other').toLowerCase();
        if (cat.includes('fit') || cat.includes('health')) {
          const fitnessQuests = [
            { title: 'Side Quest: Drink 3L of water today', desc: 'Hydrate fully today. 3L before 9pm. Input for the engine.' },
            { title: 'Side Quest: Stretching session', desc: 'Perform a 10-minute full body stretching routine tonight to improve recovery and prevent injury.' },
            { title: 'Side Quest: 15-minute quick walk', desc: 'Lace your shoes and go outside for a rapid 15-minute walk right after dinner.' }
          ];
          const choice = fitnessQuests[Math.floor(Math.random() * fitnessQuests.length)];
          sideQuestTitle = choice.title;
          sideQuestDesc = choice.desc;
        } else if (cat.includes('wealth') || cat.includes('sav') || cat.includes('learn') || cat.includes('productivity') || cat.includes('startup') || cat.includes('business')) {
          const businessQuests = [
            { title: 'Side Quest: Read 10 pages of a book', desc: 'Any professional or educational book. 10 pages before sleep. Input for the mind.' },
            { title: 'Side Quest: Clear your inbox', desc: 'Reach inbox zero or delete/archive 15 old emails to clear mental friction.' },
            { title: 'Side Quest: Post one helpful insight', desc: 'Share one lesson or strategic insight on Twitter or LinkedIn today.' }
          ];
          const choice = businessQuests[Math.floor(Math.random() * businessQuests.length)];
          sideQuestTitle = choice.title;
          sideQuestDesc = choice.desc;
        } else {
          const generalQuests = [
            { title: 'Side Quest: Read 10 pages of a book', desc: 'Any book. 10 pages before sleep. Input for the mind.' },
            { title: 'Side Quest: Plan tomorrow\'s missions', desc: 'Spend 5 minutes before bed outlining your top 3 required quests for tomorrow.' },
            { title: 'Side Quest: Reply to 5 active comments', desc: 'Engage with people in your network or community. 5 genuine replies.' }
          ];
          const choice = generalQuests[Math.floor(Math.random() * generalQuests.length)];
          sideQuestTitle = choice.title;
          sideQuestDesc = choice.desc;
        }

        const targetDate = new Date(today);
        targetDate.setHours(23, 59, 59, 999);

        const newQuest = this.actionItemRepository.create({
          milestone: currentMilestone,
          title: sideQuestTitle,
          description: sideQuestDesc,
          type: 'task',
          frequency: undefined,
          totalTarget: 1,
          isOptional: true,
          targetDate: targetDate,
        });

        await this.actionItemRepository.save(newQuest);
        this.logger.log(`Successfully added dynamic Side Quest: "${sideQuestTitle}"`);
      }
    }
  }

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
      initialProbabilityRatio: aiPlan.probability_ratio || 0,
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

  async recalculateSuccessProbability(goalId: string) {
    const goal = await this.goalRepository.findOne({
      where: { id: goalId },
      relations: [
        'milestones',
        'milestones.actionItems',
        'milestones.actionItems.steps',
      ],
    });
    if (!goal) return;

    const requiredItems: ActionItem[] = [];
    for (const m of goal.milestones) {
      for (const a of m.actionItems) {
        if (!a.isOptional) {
          requiredItems.push(a);
        }
      }
    }

    let totalRequiredDue = 0;
    let completedRequiredDue = 0;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    for (const item of requiredItems) {
      if (!item.targetDate || new Date(item.targetDate) <= today) {
        totalRequiredDue++;
        if (item.isCompleted) {
          completedRequiredDue++;
        } else if (item.steps && item.steps.length > 0) {
          const completedStepsCount = item.steps.filter((s) => s.isCompleted).length;
          completedRequiredDue += (completedStepsCount / item.steps.length) * 0.8;
        }
      }
    }

    const completionRate = totalRequiredDue === 0 ? 1.0 : (completedRequiredDue / totalRequiredDue);
    const initialProb = goal.initialProbabilityRatio || goal.probabilityRatio || 60;
    let calculatedProb = initialProb;

    if (completionRate >= 0.5) {
      // Reward success up to 99%
      calculatedProb = initialProb + (completionRate - 0.5) * 2 * (99 - initialProb);
    } else {
      // Penalize down to 10%
      calculatedProb = initialProb - (0.5 - completionRate) * 2 * (initialProb - 10);
    }

    goal.probabilityRatio = Math.round(Math.min(99, Math.max(10, calculatedProb)));

    if (goal.probabilityRatio >= 80) {
      goal.feasibility = 'can be done';
      goal.feasibilityReason = `Excellent execution! You've maintained a flawless streak, pushing your success chances to ${goal.probabilityRatio}%.`;
    } else if (goal.probabilityRatio >= 55) {
      goal.feasibility = 'moderate';
      goal.feasibilityReason = `Good progress, but consistency is key. Keep finishing daily quests to raise your success probability above 80% (currently ${goal.probabilityRatio}%).`;
    } else {
      goal.feasibility = 'low';
      goal.feasibilityReason = `Alert: Multiple missed quests have dragged your success probability down to ${goal.probabilityRatio}%. Complete today's missions to recover.`;
    }

    await this.goalRepository.save(goal);
    this.logger.log(`Goal ${goalId} success probability updated to ${goal.probabilityRatio}%`);
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
    const saved = await this.actionItemRepository.save(actionItem);
    await this.recalculateSuccessProbability(actionItem.milestone.goal.id);
    return saved;
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
    
    const saved = await this.taskStepRepository.save(step);
    await this.recalculateSuccessProbability(step.actionItem.milestone.goal.id);
    return saved;
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

  async deleteGoal(goalId: string) {
    const goal = await this.goalRepository.findOne({ where: { id: goalId } });
    if (!goal) {
      throw new NotFoundException(`Goal with ID ${goalId} not found`);
    }
    await this.goalRepository.remove(goal);
    return { success: true };
  }
}
