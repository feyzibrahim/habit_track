import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FriendsController } from './friends.controller';
import { FriendsService } from './friends.service';
import { Friend } from './friend.entity';
import { Goal } from '../goals/goal.entity';
import { XpEvent } from '../xp/xp-event.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([Friend, Goal, XpEvent]), UsersModule],
  controllers: [FriendsController],
  providers: [FriendsService]
})
export class FriendsModule {}
