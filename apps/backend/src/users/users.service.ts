import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findByEmail(email: string): Promise<User | undefined> {
    const user = await this.usersRepository.findOne({ where: { email } });
    return user || undefined;
  }

  async findById(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async create(email: string, passwordHash: string, firstName?: string, lastName?: string): Promise<User> {
    const user = this.usersRepository.create({ email, passwordHash, firstName, lastName });
    return this.usersRepository.save(user);
  }

  async update(id: string, data: Partial<User>): Promise<User> {
    const user = await this.findById(id);
    Object.assign(user, data);
    return this.usersRepository.save(user);
  }

  async createGuest(): Promise<User> {
    const user = this.usersRepository.create({ isGuest: true });
    return this.usersRepository.save(user);
  }

  async upgradeGuest(
    id: string,
    email: string,
    passwordHash: string,
    firstName?: string,
    lastName?: string,
  ): Promise<User> {
    const user = await this.findById(id);
    if (!user.isGuest) {
      throw new BadRequestException('User is already registered.');
    }

    const existing = await this.findByEmail(email);
    if (existing && existing.id !== user.id) {
      throw new BadRequestException('Email is already in use.');
    }

    user.email = email;
    user.passwordHash = passwordHash;
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    user.isGuest = false;

    return this.usersRepository.save(user);
  }
}
