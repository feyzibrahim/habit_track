import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiModule } from './ai/ai.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ActionItem } from './goals/action-item.entity';
import { Goal } from './goals/goal.entity';
import { GoalsModule } from './goals/goals.module';
import { Milestone } from './goals/milestone.entity';
import { TaskStep } from './goals/task-step.entity';
import { User } from './users/user.entity';
import { UsersModule } from './users/users.module';
import { Friend } from './friends/friend.entity';
import { FriendsModule } from './friends/friends.module';
import { XpEvent } from './xp/xp-event.entity';
import { XpModule } from './xp/xp.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: ['.env'],
      isGlobal: true,
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10) || 5432,
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'habit_track',
      entities: [User, Goal, Milestone, ActionItem, TaskStep, Friend, XpEvent],
      synchronize: true, // Use only in development
      ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
    }),
    UsersModule,
    AuthModule,
    AiModule,
    GoalsModule,
    FriendsModule,
    XpModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
