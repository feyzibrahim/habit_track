import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { XpEvent } from './xp-event.entity';
import { XpService } from './xp.service';
import { XpController } from './xp.controller';

@Module({
  imports: [TypeOrmModule.forFeature([XpEvent])],
  controllers: [XpController],
  providers: [XpService],
  exports: [XpService],
})
export class XpModule {}
