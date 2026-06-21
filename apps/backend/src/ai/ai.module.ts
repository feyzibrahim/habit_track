import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { Goal } from '../goals/goal.entity';
import { Milestone } from '../goals/milestone.entity';
import { ActionItem } from '../goals/action-item.entity';
import { TaskStep } from '../goals/task-step.entity';
import { User } from '../users/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Goal, Milestone, ActionItem, TaskStep, User]),
  ],
  providers: [AiService],
  controllers: [AiController],
  exports: [AiService],
})
export class AiModule {}
