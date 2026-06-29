import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WaitlistUser } from './waitlist-user.entity';
import { WaitlistService } from './waitlist.service';
import { WaitlistController } from './waitlist.controller';

@Module({
  imports: [TypeOrmModule.forFeature([WaitlistUser])],
  providers: [WaitlistService],
  controllers: [WaitlistController],
  exports: [WaitlistService],
})
export class WaitlistModule {}
