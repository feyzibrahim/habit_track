import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiModule } from '../ai/ai.module';
import { ActionItem } from './action-item.entity';
import { Goal } from './goal.entity';
import { GoalsController } from './goals.controller';
import { GoalsService } from './goals.service';
import { Milestone } from './milestone.entity';
import { TaskStep } from './task-step.entity';

import { XpModule } from '../xp/xp.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Goal, Milestone, ActionItem, TaskStep]),
    AiModule,
    XpModule,
  ],
  controllers: [GoalsController],
  providers: [GoalsService],
  exports: [GoalsService],
})
export class GoalsModule {}
